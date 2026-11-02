/**
 * RcTool Live2D Viewer
 * 依赖：live2dcubismcore / pixi.js 6 / pixi-live2d-display(cubism4)
 * 通过 window.__rcPost 把「加载中 / 就绪 / 失败」回传给 Flutter 宿主。
 */
var modelPath = '../models/Haru/Haru.model3.json';
var canvas = document.getElementById('live2d-canvas');
var statusNode = document.getElementById('live2d-status');

var app = null;
var model = null;
var fitScheduled = false;

// 缩放：Flutter 侧滑块通过 setZoom 调整，1 表示「完整贴合画面」
var MIN_ZOOM = 0.45;
var MAX_ZOOM = 1.8;
var zoom = 1.0;

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

function scheduleFit() {
  if (fitScheduled) return;
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
  refit: fitModelToStage
};

function reportError(error) {
  var message = (error && (error.message || error)) || '未知错误';
  setStatus('Live2D 加载失败：' + message, 'error');
  post({ type: 'error', message: String(message) });
}

// 启动
loadModel().catch(reportError);
