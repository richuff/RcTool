const modelPath = '../models/Haru/Haru.model3.json';
const canvas = document.getElementById('live2d-canvas');
const statusNode = document.getElementById('live2d-status');

let app;
let model;

function setStatus(message, ready = false) {
  statusNode.textContent = message;
  statusNode.classList.toggle('ready', ready);
}

function fitModelToStage() {
  if (!model || !app) return;

  const width = app.renderer.width;
  const height = app.renderer.height;
  const scale = Math.min(width / model.width, height / model.height) * 0.82;

  model.scale.set(scale);
  model.anchor.set(0.5, 0.5);
  model.position.set(width / 2, height * 0.56);
}

function randomInt(max) {
  return Math.floor(Math.random() * max);
}

async function createApp() {
  app = new PIXI.Application({
    view: canvas,
    autoStart: true,
    resizeTo: window,
    transparent: true,
    antialias: true,
  });
}

async function loadModel(path = modelPath) {
  setStatus(`Loading model: ${path}`);

  if (!app) await createApp();
  if (model) {
    app.stage.removeChild(model);
    model.destroy({ children: true, texture: false, baseTexture: false });
    model = null;
  }

  model = await PIXI.live2d.Live2DModel.from(path, {
    autoInteract: false,
  });

  model.interactive = true;
  model.buttonMode = true;
  model.on('pointertap', () => playMotion('TapBody'));

  app.stage.addChild(model);
  fitModelToStage();
  setStatus('Live2D model ready', true);
}

function playMotion(group = 'TapBody', index) {
  if (!model) return;
  const motionIndex = Number.isInteger(index) ? index : undefined;
  model.motion(group, motionIndex ?? randomInt(4));
}

function setExpression(name = 'F01') {
  if (!model) return;
  model.expression(name);
}

window.addEventListener('resize', fitModelToStage);

window.live2dBridge = {
  loadModel,
  playMotion,
  setExpression,
};

loadModel().catch((error) => {
  console.error(error);
  setStatus(`Live2D load failed: ${error.message || error}`);
});
