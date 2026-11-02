/**
 * RcTool Live2D Viewer
 * 依赖：live2dcubismcore / pixi.js 6 / pixi-live2d-display(cubism4)
 * 通过 window.__rcPost 把「加载中 / 就绪 / 失败」回传给 Flutter 宿主。
 */
var DEFAULT_MODEL_PATH = '../models/Haru/Haru.model3.json';
var modelPath = DEFAULT_MODEL_PATH;

/**
 * 支持由 Flutter 通过 `?model=<url>` 指定模型：
 *   - 随包模型：/assets/live2d/models/Haru/Haru.model3.json
 *   - 外部模型：/ext/<相对路径>/xxx.model3.json（由本机静态服务读磁盘）
 */
function resolveInitialModel() {
  try {
    var search = window.location.search || '';
    var match = /[?&]model=([^&]*)/.exec(search);
    if (match && match[1]) {
      var decoded = decodeURIComponent(match[1].replace(/\+/g, ' '));
      if (decoded) return decoded;
    }
  } catch (e) {
    /* 解析失败时用默认模型 */
  }
  return DEFAULT_MODEL_PATH;
}
var canvas = document.getElementById('live2d-canvas');
var statusNode = document.getElementById('live2d-status');

var app = null;
var model = null;
var fitScheduled = false;

// 缩放：Flutter 侧滑块通过 setZoom 调整，1 表示「完整贴合画面」
var MIN_ZOOM = 0.45;
var MAX_ZOOM = 1.8;
var zoom = 1.0;

/**
 * 口型联动：音频由 Flutter 原生播放器解码，WebView 拿不到音频采样，
 * 所以这里用「音节包络」模拟说话的张口节奏（快张慢合 + 乐句起伏），
 * 在每帧模型更新前写入 ParamMouthOpenY，暂停时平滑归零。
 */
var lipSyncEnabled = false;
var lipSyncIntensity = 0.9;
var mouthValue = 0;
var mouthPhase = 0;
var phrasePhase = 0;
var mouthAttached = false;
var lastMouthAt = 0;

function post(payload) {
  if (typeof window.__rcPost === 'function') {
    window.__rcPost(payload);
  }
}

function setStatus(message, state) {
  if (!statusNode) return;
  statusNode.textContent = message;
  statusNode.classList.toggle('ready', state === 'ready');
  statusNode.classList.toggle('error', state === 'error');
}

function getLive2DModelClass() {
  return window.PIXI &&
    window.PIXI.live2d &&
    window.PIXI.live2d.Live2DModel &&
    window.PIXI.live2d.Live2DModel.from
    ? window.PIXI.live2d.Live2DModel
    : null;
}

function missingRuntime() {
  var missing = [];
  if (!window.Live2DCubismCore) missing.push('Live2D Cubism Core');
  if (!window.PIXI) missing.push('PixiJS');
  if (!getLive2DModelClass()) missing.push('pixi-live2d-display(Cubism4)');
  return missing;
}

/** 等待 UMD 脚本就绪（WebView 内脚本顺序执行，这里只是兜底） */
function waitForRuntime(timeoutMs) {
  var deadline = Date.now() + (timeoutMs || 15000);
  return new Promise(function (resolve, reject) {
    (function poll() {
      var missing = missingRuntime();
      if (missing.length === 0) {
        resolve();
        return;
      }
      if (Date.now() > deadline) {
        reject(new Error('运行库未加载：' + missing.join('、')));
        return;
      }
      setTimeout(poll, 100);
    })();
  });
}

function createApp() {
  app = new PIXI.Application({
    view: canvas,
    autoStart: true,
    resizeTo: window,
    transparent: true,
    backgroundAlpha: 0,
    antialias: true,
    resolution: Math.min(window.devicePixelRatio || 1, 2),
    autoDensity: true,
    powerPreference: 'high-performance'
  });
}

function stageSize() {
  if (!app) return { width: window.innerWidth, height: window.innerHeight };
  return {
    width: app.screen.width || window.innerWidth,
    height: app.screen.height || window.innerHeight
  };
}

function fitModelToStage() {
  if (!model) return;
  var size = stageSize();
  if (!size.width || !size.height) return;

  var modelWidth = model.width || 1;
  var modelHeight = model.height || 1;
  // 0.86 先留出边距，再乘以用户缩放；竖屏下也不会裁到头发/脚
  var scale =
    Math.min(size.width / modelWidth, size.height / modelHeight) * 0.86 * zoom;

  model.scale.set(scale);
  model.anchor.set(0.5, 0.5);
  // 缩放变小时模型仍以画面偏下位置为锚点，视觉上更居中
  model.position.set(size.width / 2, size.height * (0.56 + (1 - zoom) * 0.04));
}

/** 设置缩放倍率（0.45 ~ 1.8），返回实际生效值 */
function setZoom(value) {
  var next = Number(value);
  if (!isFinite(next)) return zoom;
  zoom = Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, next));
  fitModelToStage();
  return zoom;
}

/** 每帧（模型更新前）写入嘴部开合；暂停时平滑回到闭合 */
function applyMouth() {
  if (!model || !model.internalModel) return;
  var core = model.internalModel.coreModel;
  if (!core || typeof core.setParameterValueById !== 'function') return;

  var now =
    typeof performance !== 'undefined' && performance.now
      ? performance.now()
      : Date.now();
  var dt = lastMouthAt ? Math.min((now - lastMouthAt) / 1000, 0.1) : 0.016;
  lastMouthAt = now;

  if (!lipSyncEnabled) {
    mouthValue += (0 - mouthValue) * Math.min(1, dt * 10);
    if (mouthValue < 0.002) mouthValue = 0;
    if (mouthValue === 0) return;
    try {
      core.setParameterValueById('ParamMouthOpenY', mouthValue);
    } catch (e) {
      /* 没有该参数时忽略 */
    }
    return;
  }

  // 音节节奏：主频随乐句轻微变化，叠加两层谐波，避免机械的等幅开合
  mouthPhase += dt * (7.4 + 2.6 * Math.sin(now / 1900));
  phrasePhase += dt;
  var phrase = 0.74 + 0.26 * Math.sin(phrasePhase * 0.85);
  var tone = Math.pow(Math.abs(Math.sin(mouthPhase)), 1.5);
  var wobble = 0.16 * Math.sin(mouthPhase * 2.7 + 1.3);
  var target = (0.1 + 0.8 * tone + wobble) * phrase * lipSyncIntensity;
  target = Math.min(1, Math.max(0, target));

  // 张口快、闭口慢，看起来更像在唱而不是在抖
  var speed = target > mouthValue ? 18 : 9;
  mouthValue += (target - mouthValue) * Math.min(1, dt * speed);

  try {
    core.setParameterValueById('ParamMouthOpenY', mouthValue);
  } catch (e) {
    /* 没有该参数时忽略 */
  }
}

/** 把口型写入挂到模型的生命周期上（模型更新前，动作与物理都已算完） */
function attachMouthHook() {
  if (!model || !model.internalModel || mouthAttached) return;
  if (typeof model.internalModel.on !== 'function') return;
  model.internalModel.on('beforeModelUpdate', applyMouth);
  mouthAttached = true;
}

function scheduleFit() {  if (fitScheduled) return;
  fitScheduled = true;
  requestAnimationFrame(function () {
    fitScheduled = false;
    try {
      fitModelToStage();
    } catch (e) {
      /* 尺寸变化失败不应中断渲染 */
    }
  });
}

function randomInt(max) {
  return Math.floor(Math.random() * Math.max(max, 1));
}

function playMotion(group, index) {
  if (!model) return false;
  var groups = (model.internalModel &&
    model.internalModel.settings &&
    model.internalModel.settings.motions) || {};
  var list = groups[group];
  if (!list || !list.length) {
    return false;
  }
  var target = Number.isInteger(index) ? index : randomInt(list.length);
  try {
    model.motion(group, target);
    return true;
  } catch (e) {
    return false;
  }
}

function setExpression(name) {
  if (!model) return;
  try {
    model.expression(name || 'F01');
  } catch (e) {
    /* 表情不存在时忽略 */
  }
}

function bindInteractions() {
  if (!model) return;

  // 点击命中区域：头部换表情，身体换动作
  model.on('hit', function (hitAreas) {
    if (hitAreas.indexOf('Head') >= 0) {
      setExpression('F0' + (1 + randomInt(8)));
      playMotion('TapHead');
      return;
    }
    playMotion('TapBody');
  });

  model.on('pointertap', function () {
    if (!model) return;
    if (!playMotion('TapBody')) playMotion('Extra');
  });
}

async function loadModel(path) {
  var target = path || modelPath;
  setStatus('正在加载模型…');

  // 脚本标签是同步执行的，此时运行库要么已就绪，要么永远不会有，直接报原因
  var missing = missingRuntime();
  if (missing.length) {
    throw new Error('运行库未加载：' + missing.join('、') +
      '（请确认 assets/live2d/viewer/vendor 已随 APK 打包）');
  }

  post({ type: 'progress', value: 20 });
  await waitForRuntime(3000);
  post({ type: 'progress', value: 45 });

  if (!app) createApp();
  post({ type: 'progress', value: 60 });

  if (model) {
    try {
      app.stage.removeChild(model);
      model.destroy({ children: true, texture: false, baseTexture: false });
    } catch (e) {
      /* 旧模型清理失败可忽略 */
    }
    model = null;
    mouthAttached = false;
  }

  var Live2DModel = getLive2DModelClass();
  model = await Live2DModel.from(target, {
    autoInteract: true,
    autoUpdate: true
  });
  post({ type: 'progress', value: 85 });

  model.interactive = true;
  app.stage.addChild(model);

  bindInteractions();
  attachMouthHook();
  fitModelToStage();
  // 首帧尺寸可能还是 0，等一帧再校准一次
  requestAnimationFrame(function () {
    fitModelToStage();
    playMotion('Idle');
  });

  if (app.ticker && !app.ticker.started) app.ticker.start();

  setStatus('Live2D 已就绪', 'ready');
  post({ type: 'ready' });
  return model;
}

window.addEventListener('resize', scheduleFit);
window.addEventListener('orientationchange', function () {
  setTimeout(scheduleFit, 120);
});
window.addEventListener('message', scheduleFit);

window.live2dBridge = {
  loadModel: function (path) {
    return loadModel(path).catch(reportError);
  },
  playMotion: playMotion,
  setExpression: setExpression,
  setZoom: setZoom,
  getZoom: function () {
    return zoom;
  },
  setLipSync: function (enabled, intensity) {
    lipSyncEnabled = !!enabled;
    if (typeof intensity === 'number' && isFinite(intensity)) {
      lipSyncIntensity = Math.min(1, Math.max(0.2, intensity));
    }
    if (lipSyncEnabled) attachMouthHook();
    return lipSyncEnabled;
  },
  getLipSync: function () {
    return lipSyncEnabled;
  },
  refit: fitModelToStage
};

function reportError(error) {
  var message = (error && (error.message || error)) || '未知错误';
  setStatus('Live2D 加载失败：' + message, 'error');
  post({ type: 'error', message: String(message) });
}

// 启动
loadModel(resolveInitialModel()).catch(reportError);
