import * as THREE from 'three';

/** Toạ độ bố cục cảnh — dùng chung cho long, môi trường và camera để mọi thứ khớp nhau. */

/** Cột đá mà long đậu lên (bên phải khung hình). */
export const SPIRE_CENTER = new THREE.Vector3(8.2, 0, 0.5);
export const SPIRE_TOP = 10.2;

/** Tư thế đậu: điểm đầu hướng về người xem. */
export const PERCH_HEAD = new THREE.Vector3(5.6, 11.9, 3.8);

/** Vòng bay quanh đỉnh núi giữa cảnh. */
export const CIRCLE_CENTER = new THREE.Vector3(0, 16, -14);
export const CIRCLE_RADIUS = 13;

export const CAMERA_DESKTOP = {
  pos: new THREE.Vector3(0, 6.0, 25.5),
  look: new THREE.Vector3(2.1, 8.2, 0),
};

export const CAMERA_PORTRAIT = {
  pos: new THREE.Vector3(-1.8, 6.8, 29),
  look: new THREE.Vector3(4.6, 9.8, 0),
};
