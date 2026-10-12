import { AdaptiveDpr } from '@react-three/drei';
import { Canvas, useFrame, useThree } from '@react-three/fiber';
import { Bloom, EffectComposer, ToneMapping, Vignette } from '@react-three/postprocessing';
import { ToneMappingMode } from 'postprocessing';
import { Suspense, useEffect, useMemo, useState } from 'react';
import { isPhotoMode, phaseStore, photoPreset } from '../app/store';
import { DragonRig } from '../dragon/rig';
import { assetExists, DRAGON_MODEL_URL } from '../services/assets';
import { CameraRig } from './CameraRig';
import { Environment } from './Environment';
import { CAMERA_DESKTOP } from './layout';
import { GlbDragonView } from './glbDragon';

function DragonView({ reducedMotion, onSettled }: { reducedMotion: boolean; onSettled: () => void }) {
  const camera = useThree((s) => s.camera);
  const rig = useMemo(() => new DragonRig(), []);
  const frames = useMemo(() => ({ n: 0 }), []);
  useEffect(() => {
    rig.setMotionScale(reducedMotion ? 0.15 : 1);
  }, [reducedMotion, rig]);
  useEffect(() => {
    rig.onAdvance = (p) => phaseStore.set(p);
    // Chế độ ảnh: đồng bộ pha nội bộ của rig sang store để UI (lớp phủ lửa…) theo kịp.
    const photo = photoPreset();
    if (photo) phaseStore.set(photo.phase);
    return () => rig.dispose();
  }, [rig]);
  useFrame((state, delta) => {
    rig.update(Math.min(delta, 0.05), state.clock.elapsedTime, camera);
    // Chế độ ảnh: vẽ đủ số khung cho vật liệu/particle ổn rồi dừng vòng vẽ,
    // để máy chụp tĩnh (virtual time) chốt được khung.
    if (isPhotoMode() && ++frames.n === 45) onSettled();
  });
  return <primitive object={rig.root} />;
}

/** Đo một lần lúc mở: có model GLB thật thì dùng, không thì chạy long thủ công. */
function useModelProbe(): boolean {
  const [ok, setOk] = useState(false);
  useEffect(() => {
    let live = true;
    void assetExists(DRAGON_MODEL_URL).then((exists) => {
      if (live) setOk(exists);
    });
    return () => {
      live = false;
    };
  }, []);
  return ok;
}

function SceneFallback() {
  return (
    <mesh>
      <boxGeometry />
      <meshBasicMaterial color="#140a06" />
    </mesh>
  );
}

export interface DragonSceneProps {
  active: boolean;
  quality: 'high' | 'low';
  reducedMotion: boolean;
}

export function DragonScene({ active, quality, reducedMotion }: DragonSceneProps) {
  const hasModel = useModelProbe();
  const high = quality === 'high';
  const [frozen, setFrozen] = useState(false);
  return (
    <Canvas
      flat={high}
      dpr={high ? [1, 2] : [1, 1.5]}
      frameloop={active && !frozen ? 'always' : 'never'}
      camera={{ fov: 55, near: 0.5, far: 900, position: CAMERA_DESKTOP.pos.toArray() }}
      gl={{ antialias: high, powerPreference: 'high-performance' }}
      onCreated={({ gl, scene }) => {
        gl.toneMappingExposure = 1.12;
        // Tay nắm kiểm tra: cho phép công cụ gỡ lỗi soi cây cảnh từ console.
        (window as unknown as { __tlScene: unknown }).__tlScene = scene;
      }}
      performance={{ min: 0.5 }}
      fallback={<SceneFallback />}
    >
      <color attach="background" args={['#070302']} />
      <fogExp2 attach="fog" args={['#140a06', 0.0145]} />
      <Suspense fallback={null}>
        <Environment quality={quality} />
        {hasModel ? <GlbDragonView url={DRAGON_MODEL_URL} /> : <DragonView reducedMotion={reducedMotion} onSettled={() => setFrozen(true)} />}
        {high && (
          <EffectComposer multisampling={0}>
            <Bloom intensity={1.2} luminanceThreshold={0.52} luminanceSmoothing={0.22} mipmapBlur radius={0.75} />
            <ToneMapping mode={ToneMappingMode.ACES_FILMIC} />
            <Vignette offset={0.2} darkness={0.75} />
          </EffectComposer>
        )}
      </Suspense>
      <CameraRig />
      <AdaptiveDpr pixelated />
    </Canvas>
  );
}
