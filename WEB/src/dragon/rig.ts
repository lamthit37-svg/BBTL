import * as THREE from 'three';
import { clamp, clamp01, damp, easeInOutCubic, easeOutCubic, lerp, quadBezier, smoothstep } from '../app/mathx';
import { pointerNdc } from '../app/pointer';
import { photoPreset, Phase, phaseStore } from '../app/store';
import { CIRCLE_CENTER, CIRCLE_RADIUS, PERCH_HEAD, SPIRE_CENTER, SPIRE_TOP } from '../scenes/layout';
import { FireBreath } from '../particles/fireBreath';
import { SparkField } from '../particles/sparks';
import { CHAIN_LEN, COIL_START, SEG_LEN, initialChain, relaxChain, widthAt } from './chain';
import { buildFlow, FlowRig } from './flow';
import { buildHead, HeadRig } from './head';
import { buildLegs, LegsRig } from './limbs';
import { lavaClock, makeLavaMaterial } from './materials';

const N = CHAIN_LEN;
const UP = new THREE.Vector3(0, 1, 0);
const X_AXIS = new THREE.Vector3(1, 0, 0);

export const INTRO_T = 9;
export const CIRCLE_T = 7.5;
export const LANDING_T = 5;
export const ROAR_T = 3.4;

const ROAR_TARGET = new THREE.Vector3(2.2, 8.8, 9.8);

const INTRO_CURVE = new THREE.CatmullRomCurve3([
  new THREE.Vector3(-54, 27, -66),
  new THREE.Vector3(-27, 22, -40),
  new THREE.Vector3(-2, 27, -21),
  new THREE.Vector3(13, 18, -6),
  new THREE.Vector3(6.5, 13.2, 1.5),
]);

// Nghiêng người theo độ cong — biên độ và dấu chỉnh khi soi khung thật.
const ROLL_GAIN = 14;
const ROLL_MAX = 0.45;

// Xoắn ốc quấn quanh cột đá khi đậu.
const COIL_R = 2.75;
const COIL_A0 = 2.4;
const COIL_DA = 0.44;

const coilPoint = (k: number, out: THREE.Vector3): THREE.Vector3 =>
  out.set(
    SPIRE_CENTER.x + Math.cos(COIL_A0 + k * COIL_DA) * COIL_R,
    SPIRE_TOP + 0.75 - k * 0.16,
    SPIRE_CENTER.z + Math.sin(COIL_A0 + k * COIL_DA) * COIL_R,
  );

const _v1 = new THREE.Vector3();
const _v2 = new THREE.Vector3();
const _v3 = new THREE.Vector3();
const _tangent = new THREE.Vector3();
const _right = new THREE.Vector3();
const _up = new THREE.Vector3();
const _m4 = new THREE.Matrix4();
const _qBase = new THREE.Quaternion();
const _qEuler = new THREE.Quaternion();
const _qi = new THREE.Quaternion();
const GOLD = new THREE.Color(1.0, 0.62, 0.18);
const EMBER = new THREE.Color(0.9, 0.3, 0.08);

/** Tư thế đậu: mô phỏng chuỗi với lực kéo xoắn ốc tới khi ổn định — dùng cho skip và pha idle. */
function buildPerchPose(): THREE.Vector3[] {
  const pts = initialChain(PERCH_HEAD, new THREE.Vector3(0, 0, -1));
  const target = new THREE.Vector3();
  for (let step = 0; step < 90; step++) {
    relaxChain(pts, SEG_LEN);
    for (let i = COIL_START; i < N; i++) {
      pts[i].lerp(coilPoint(i - COIL_START, target), 0.09);
    }
  }
  return pts;
}
const PERCH_POSE = buildPerchPose();

/**
 * Hỏa Long: thân chuỗi 34 đốt chạy theo đầu, máy pha intro → bay vòng → đáp → đậu
 * → gầm phun lửa → đăng nhập. Toàn bộ dựng bằng primitive + vật liệu lava.
 */
export class DragonRig {
  readonly root = new THREE.Group();
  onAdvance: (p: Phase) => void = () => {};

  private readonly body: THREE.InstancedMesh;
  private readonly spikes: THREE.InstancedMesh;
  private readonly bodyMat: THREE.MeshStandardMaterial;
  private readonly head: HeadRig;
  private readonly flow: FlowRig;
  private readonly legs: LegsRig;
  private readonly fire: FireBreath;
  private readonly sparks: SparkField;
  private readonly headLight: THREE.PointLight;

  private readonly chain: THREE.Vector3[] = initialChain(PERCH_HEAD, new THREE.Vector3(0, 0, -1));
  private readonly roll = new Array<number>(N).fill(0);
  private readonly headPos = PERCH_HEAD.clone();
  private readonly headPrev = PERCH_HEAD.clone();
  private readonly forward = new THREE.Vector3(0, 0, 1);

  private phase: Phase = 'intro';
  private phaseT = 0;
  private coilBlend = 0;
  private circleAngle = 0;
  private circleRadius = CIRCLE_RADIUS;
  private readonly landFrom = new THREE.Vector3();
  private readonly landCtrl = new THREE.Vector3();
  private roarCurve: THREE.CatmullRomCurve3 | null = null;
  private gazeYaw = 0;
  private gazePitch = 0;
  private jawOpen = 0;
  private heat = 1;
  private motionScale = 1;
  private blinkIn = 2.5;
  private blinkT = 0;
  private sparkIn = 0.4;
  private smokeIn = 5;
  private booted = false;

  constructor() {
    this.bodyMat = makeLavaMaterial({ crackScale: 0.45, heat: 1.1, base: '#241812', roughness: 0.5, metalness: 0.3 });
    const plateGeo = new THREE.SphereGeometry(0.5, 10, 8);
    this.body = new THREE.InstancedMesh(plateGeo, this.bodyMat, N - 1);
    this.spikes = new THREE.InstancedMesh(new THREE.ConeGeometry(0.16, 0.55, 5), this.bodyMat, N - 3);
    for (const mesh of [this.body, this.spikes]) {
      mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
      mesh.frustumCulled = false;
    }

    this.head = buildHead();
    this.flow = buildFlow();
    this.head.group.add(this.flow.headGroup);
    this.legs = buildLegs();
    this.fire = new FireBreath();
    this.sparks = new SparkField();
    this.headLight = new THREE.PointLight('#ff6a22', 80, 30, 2);

    this.root.add(this.body, this.spikes, this.head.group, this.legs.group, this.flow.tailFlame, this.fire.points, this.sparks.points, this.headLight);

    // Chế độ ảnh: vào thẳng pha chỉ định ở đúng khoảnh khắc để chụp kiểm định.
    const photo = photoPreset();
    if (photo) {
      this.setupPhotoPreset(photo.phase, photo.time);
    }
  }

  private setupPhotoPreset(phase: Phase, time: number): void {
    if (phase === 'idle' || phase === 'login') {
      this.snapToPerch();
      this.enterPhase(phase);
      this.coilBlend = 1;
    } else if (phase === 'intro') {
      const p0 = INTRO_CURVE.getPointAt(easeInOutCubic(clamp01(time / INTRO_T)));
      const p1 = INTRO_CURVE.getPointAt(clamp01(time / INTRO_T - 0.04));
      this.headPos.copy(p0);
      this.headPrev.copy(p0);
      this.forward.subVectors(p0, p1).normalize();
      for (let i = 0; i < N; i++) this.chain[i].copy(this.headPos).addScaledVector(this.forward, -i * SEG_LEN);
      this.enterPhase('intro');
    } else if (phase === 'circle') {
      this.enterPhase('circle');
    } else if (phase === 'landing') {
      this.headPos.set(1.5, 12.5, -5);
      this.headPrev.copy(this.headPos);
      for (let i = 0; i < N; i++) this.chain[i].copy(this.headPos).add(new THREE.Vector3(0, 0, -1).multiplyScalar(i * SEG_LEN));
      this.enterPhase('landing');
    } else if (phase === 'roar') {
      this.snapToPerch();
      this.enterPhase('roar');
      this.coilBlend = 0;
    }
    this.phaseT = time;
  }

  setMotionScale(scale: number): void {
    this.motionScale = scale;
  }

  private enterPhase(next: Phase): void {
    this.phase = next;
    this.phaseT = 0;
    if (next === 'circle') {
      this.circleAngle = Math.atan2(this.headPos.z - CIRCLE_CENTER.z, this.headPos.x - CIRCLE_CENTER.x);
      this.circleRadius = Math.hypot(this.headPos.x - CIRCLE_CENTER.x, this.headPos.z - CIRCLE_CENTER.z);
    } else if (next === 'landing') {
      this.landFrom.copy(this.headPos);
      this.landCtrl.copy(this.headPos).lerp(PERCH_HEAD, 0.5).add(_v1.set(0.5, 4.2, 1.4));
    } else if (next === 'roar') {
      const ctrl = this.headPos.clone().lerp(ROAR_TARGET, 0.5).add(new THREE.Vector3(0.6, 3.4, 0.4));
      this.roarCurve = new THREE.CatmullRomCurve3([this.headPos.clone(), ctrl, ROAR_TARGET.clone()]);
    }
  }

  private advance(next: Phase): void {
    this.enterPhase(next);
    this.onAdvance(next);
  }

  private snapToPerch(): void {
    for (let i = 0; i < N; i++) this.chain[i].copy(PERCH_POSE[i]);
    this.headPos.copy(PERCH_HEAD);
    this.headPrev.copy(PERCH_HEAD);
    this.coilBlend = 1;
    this.jawOpen = 0;
  }

  /** Mục tiêu vị trí đầu theo pha; trả kèm hệ số hướng mặt về phía máy. */
  private phaseGoal(out: THREE.Vector3): { face: number; coil: number; follow: number } {
    const e = this.phaseT;
    switch (this.phase) {
      case 'intro': {
        out.copy(INTRO_CURVE.getPointAt(easeInOutCubic(clamp01(e / INTRO_T))));
        return { face: 0, coil: 0, follow: 8 };
      }
      case 'circle': {
        const r = this.circleRadius;
        out.set(
          CIRCLE_CENTER.x + Math.cos(this.circleAngle) * r,
          CIRCLE_CENTER.y + Math.sin(this.circleAngle * 2.2) * 1.5,
          CIRCLE_CENTER.z + Math.sin(this.circleAngle) * r,
        );
        return { face: 0.15, coil: 0, follow: 8 };
      }
      case 'landing': {
        const t = easeInOutCubic(clamp01(e / LANDING_T));
        out.set(
          quadBezier(this.landFrom.x, this.landCtrl.x, PERCH_HEAD.x, t),
          quadBezier(this.landFrom.y, this.landCtrl.y, PERCH_HEAD.y, t),
          quadBezier(this.landFrom.z, this.landCtrl.z, PERCH_HEAD.z, t),
        );
        return { face: 0.3, coil: smoothstep(0.45, 1.0, t), follow: 6 };
      }
      case 'idle': {
        out.copy(PERCH_HEAD);
        out.x += Math.sin(e * 0.5) * 0.3 * this.motionScale;
        out.y += Math.sin(e * 1.35) * 0.16 * this.motionScale;
        return { face: 0.72, coil: 1, follow: 2.4 };
      }
      case 'roar': {
        const tt = clamp01(e / ROAR_T);
        out.copy(this.roarCurve ? this.roarCurve.getPointAt(easeOutCubic(tt)) : ROAR_TARGET);
        return { face: 0.9, coil: 0, follow: 5 };
      }
      case 'login': {
        out.copy(PERCH_HEAD).add(_v3.set(0.3, -0.1, 0.4));
        out.x += Math.sin(e * 0.4) * 0.2 * this.motionScale;
        out.y += Math.sin(e * 1.2) * 0.1 * this.motionScale;
        return { face: 0.85, coil: 1, follow: 1.4 };
      }
    }
  }

  private placeLegs(): void {
    for (let li = 0; li < this.legs.legs.length; li++) {
      const leg = this.legs.legs[li];
      const idx = leg.front ? 5 : 12;
      const p = this.chain[idx];
      _tangent.subVectors(this.chain[idx - 1], p);
      if (_tangent.lengthSq() < 1e-8) _tangent.set(0, 0, 1);
      _tangent.normalize();
      _right.crossVectors(_tangent, UP);
      if (_right.lengthSq() < 1e-6) _right.set(1, 0, 0);
      _right.normalize();
      const w = widthAt(idx, N);
      leg.root.position.copy(p).addScaledVector(_right, leg.side * w * 0.66);
      leg.root.position.y -= w * 0.4;
      _up.copy(UP).addScaledVector(_tangent, -UP.dot(_tangent)).normalize();
      _m4.makeBasis(_right, _up, _tangent);
      leg.root.quaternion.setFromRotationMatrix(_m4);
    }
  }

  update(dt: number, elapsed: number, camera: THREE.Camera): void {
    // Lệnh từ UI
    if (phaseStore.skipRequested) {
      phaseStore.skipRequested = false;
      if (this.phase !== 'idle') {
        this.snapToPerch();
        this.advance('idle');
      }
    }
    if (phaseStore.loginRequested) {
      phaseStore.loginRequested = false;
      if (this.phase === 'idle') this.advance('roar');
    }
    if (!this.booted && this.motionScale < 1 && this.phase !== 'idle') {
      // Giảm chuyển động: bỏ hoạt cảnh mở màn, đậu ngay.
      this.snapToPerch();
      this.advance('idle');
    }
    this.booted = true;

    this.phaseT += dt;
    if (this.phase === 'circle') this.circleAngle += dt * 0.5;
    const mode = this.phaseGoal(_v1);
    const k = 1 - Math.exp(-mode.follow * dt);
    this.headPos.lerp(_v1, k);

    // Hướng tiến của đầu — dùng làm trục định hướng cơ bản.
    _v2.subVectors(this.headPos, this.headPrev);
    if (_v2.lengthSq() > 1e-8) this.forward.lerp(_v2.normalize(), 0.4).normalize();
    this.headPrev.copy(this.headPos);

    // Quay đầu nhìn người xem: trục theo hướng bay, cộng góc giới hạn theo con trỏ.
    _m4.lookAt(_v2.copy(this.headPos).add(this.forward), this.headPos, UP);
    _qBase.setFromRotationMatrix(_m4);
    _v3.copy(camera.position).sub(this.headPos).normalize();
    _qi.copy(_qBase).invert();
    _v3.applyQuaternion(_qi);
    const yaw = clamp(Math.atan2(_v3.x, _v3.z), -0.55, 0.55);
    const pitch = clamp(Math.asin(clamp(_v3.y, -1, 1)), -0.32, 0.32);
    const gw = mode.face;
    const px = clamp(pointerNdc.x, -1, 1);
    const py = clamp(pointerNdc.y, -1, 1);
    this.gazeYaw = damp(this.gazeYaw, yaw * gw + px * 0.12 * gw, 3.5, dt);
    this.gazePitch = damp(this.gazePitch, pitch * gw + py * 0.1 * gw, 3.5, dt);
    _qEuler.setFromAxisAngle(X_AXIS, this.gazePitch);
    _qBase.multiply(_qEuler);
    _qEuler.setFromAxisAngle(UP, this.gazeYaw);
    _qBase.multiply(_qEuler);

    // Chuỗi thân: giữ khoảng cách rồi kéo về xoắn ốc khi đậu.
    _tangent.copy(this.forward);
    this.chain[0].copy(this.headPos).addScaledVector(_tangent, -0.55);
    relaxChain(this.chain, SEG_LEN);
    this.coilBlend = damp(this.coilBlend, mode.coil, 1.5, dt);
    if (this.coilBlend > 0.01) {
      for (let i = COIL_START; i < N; i++) {
        this.chain[i].lerp(coilPoint(i - COIL_START, _v2), this.coilBlend * clamp(3.2 * dt, 0, 0.5));
      }
      relaxChain(this.chain, SEG_LEN);
    }

    // Thân: các đốt elip ghép lớp + gai lưng, nghiêng người theo độ cong.
    const dummy = _dummy;
    for (let i = 1; i < N; i++) {
      _tangent.subVectors(this.chain[i - 1], this.chain[i]).normalize();
      dummy.position.copy(this.chain[i]);
      _m4.lookAt(_v2.copy(this.chain[i]).add(_tangent), this.chain[i], UP);
      dummy.quaternion.setFromRotationMatrix(_m4);
      if (i < N - 1) {
        _v2.subVectors(this.chain[i - 1], this.chain[i]).normalize();
        _v3.subVectors(this.chain[i], this.chain[i + 1]).normalize();
        const curv = _right.crossVectors(_v2, _v3).y;
        this.roll[i] = damp(this.roll[i], clamp(curv * ROLL_GAIN, -ROLL_MAX, ROLL_MAX), 3, dt);
      }
      dummy.rotateZ(this.roll[i]);
      const w = widthAt(i, N);
      dummy.scale.set(w, w * 0.9, SEG_LEN * 1.45);
      dummy.updateMatrix();
      this.body.setMatrixAt(i - 1, dummy.matrix);

      if (i >= 2 && i <= N - 2) {
        _v2.copy(this.chain[i]);
        _v2.y += w * 0.82;
        dummy.position.copy(_v2);
        dummy.quaternion.setFromRotationMatrix(_m4);
        dummy.rotateX(-0.55);
        dummy.scale.set(w * 0.55, 0.5 + w * 0.95, w * 0.55);
        dummy.updateMatrix();
        this.spikes.setMatrixAt(i - 2, dummy.matrix);
      }
    }
    this.body.instanceMatrix.needsUpdate = true;
    this.spikes.instanceMatrix.needsUpdate = true;

    // Đầu: vị trí, quay, hàm, chớp mắt.
    this.head.group.position.copy(this.headPos);
    this.head.group.quaternion.slerp(_qBase, 1 - Math.exp(-9 * dt));
    const tt = this.phase === 'roar' ? clamp01(this.phaseT / ROAR_T) : 0;
    const jawTarget = this.phase === 'roar' ? smoothstep(0.12, 0.4, tt) * (1 - smoothstep(0.82, 0.98, tt)) : 0;
    this.jawOpen = damp(this.jawOpen, jawTarget, 6, dt);
    this.head.jaw.rotation.x = this.jawOpen * 0.55;
    this.blinkIn -= dt;
    if (this.blinkIn <= 0) {
      this.blinkT = 0.13;
      this.blinkIn = 2.4 + Math.random() * 3.4;
    }
    if (this.blinkT > 0) this.blinkT -= dt;
    const eyeScale = this.blinkT > 0 ? 0.12 : 1;
    for (const eye of this.head.eyes) eye.scale.y = eyeScale;

    // Nhiệt: pha gầm làm vỡ dung nham rực lên.
    let heatTarget = 1;
    if (this.phase === 'roar') heatTarget = 1 + 1.15 * smoothstep(0.18, 0.45, tt) * (1 - smoothstep(0.82, 1, tt));
    else if (this.phase === 'login') heatTarget = 1.15;
    this.heat = damp(this.heat, heatTarget, 2.5, dt);
    (this.bodyMat.userData.uHeat as { value: number }).value = this.heat;
    (this.head.headMat.userData.uHeat as { value: number }).value = this.heat * 1.1;
    const legHeat = this.legs.mats.body.userData.uHeat as { value: number } | undefined;
    if (legHeat) legHeat.value = this.heat;
    const eyeK = 1 + 2.2 * (this.heat - 1);
    this.head.eyeMat.color.setRGB(3.4 * eyeK, 1.0 * Math.min(eyeK, 1.6), 0.22);
    lavaClock.value = elapsed;
    this.head.group.updateMatrixWorld(true);

    // Bờm, râu, lửa đuôi — trễ theo độ quay đầu thật.
    const headTurn = this.head.group.quaternion.angleTo(this.prevHeadQuat) / Math.max(dt, 1e-4);
    this.prevHeadQuat.copy(this.head.group.quaternion);
    this.flow.update(elapsed * lerp(0.35, 1, this.motionScale), headTurn * 0.25, 0.62 + (this.heat - 1) * 0.8);
    this.flow.tailFlame.position.copy(this.chain[N - 1]);
    _v2.subVectors(this.chain[N - 1], this.chain[N - 2]).normalize();
    this.flow.tailFlame.quaternion.setFromUnitVectors(UP, _v2);

    // Chân: thu khi bay, bám đá khi đậu.
    const tuck = this.phase === 'idle' || this.phase === 'login' || this.phase === 'roar' ? 0 : this.phase === 'landing' ? 1 - mode.coil : 1;
    this.legs.pose(clamp01(tuck), elapsed);
    this.placeLegs();

    // Hơi thở lửa
    const firing = this.phase === 'roar' && tt > 0.36 && tt < 0.8;
    this.fire.active = firing;
    if (firing) {
      _v2.copy(this.head.mouth).applyMatrix4(this.head.group.matrixWorld);
      _v3.copy(camera.position).sub(_v2).normalize();
      this.fire.emit(_v2, _v3, dt);
      this.headLight.intensity = 420;
    } else {
      this.headLight.intensity = 95 + 55 * this.heat;
    }
    this.headLight.position.copy(this.headPos).add(_v2.set(0, -0.7, 0.3));
    this.fire.update(dt);

    // L_SIG: tia lửa rơi khỏi thân + khói mũi định kỳ
    this.sparkIn -= dt;
    if (this.sparkIn <= 0) {
      this.sparkIn = 0.32;
      const i = 4 + Math.floor(Math.random() * (N - 8));
      _v2.copy(this.chain[i]);
      this.sparks.spawn({
        origin: _v2,
        vel: _v3.set((Math.random() - 0.5) * 1.2, -0.4 - Math.random(), (Math.random() - 0.5) * 1.2),
        life: 0.7 + Math.random() * 0.5,
        size: 2.4,
        gravity: -5.5,
        color: GOLD,
      });
    }
    this.smokeIn -= dt;
    if (this.smokeIn <= 0) {
      this.smokeIn = 4.5 + Math.random() * 3.5;
      _v2.copy(this.head.nose).applyMatrix4(this.head.group.matrixWorld);
      for (let s = 0; s < 5; s++) {
        this.sparks.spawn({
          origin: _v2,
          vel: _v3.set((Math.random() - 0.5) * 0.5, 0.8 + Math.random() * 0.7, (Math.random() - 0.5) * 0.5),
          life: 0.9 + Math.random() * 0.6,
          size: 3.2,
          gravity: 0.9,
          color: EMBER,
        });
      }
    }
    this.sparks.update(dt);

    // Hết pha tự nhiên
    if (this.phase === 'intro' && this.phaseT >= INTRO_T) this.advance('circle');
    else if (this.phase === 'circle' && this.phaseT >= CIRCLE_T) this.advance('landing');
    else if (this.phase === 'landing' && this.phaseT >= LANDING_T) this.advance('idle');
    else if (this.phase === 'roar' && this.phaseT >= ROAR_T) this.advance('login');
  }

  private readonly prevHeadQuat = new THREE.Quaternion();

  dispose(): void {
    this.body.geometry.dispose();
    this.spikes.geometry.dispose();
    this.bodyMat.dispose();
    this.head.dispose();
    this.flow.dispose();
    this.legs.dispose();
    this.fire.dispose();
    this.sparks.dispose();
  }
}

const _dummy = new THREE.Object3D();
