export interface AuthResult {
  ok: boolean;
  message: string;
}

const delay = (ms: number): Promise<void> => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Dịch vụ xác thực chỗ nối backend thật. Bản trình diễn luôn trả lời thất bại
 * với thông điệp trung thực — không giả đăng nhập thành công.
 */
export async function login(account: string, password: string): Promise<AuthResult> {
  if (!account.trim() || !password) return { ok: false, message: 'Vui lòng nhập tài khoản và mật khẩu.' };
  await delay(850);
  return { ok: false, message: 'Chưa kết nối máy chủ đăng nhập — đây là bản trình diễn web.' };
}

export async function register(account: string, password: string, confirm: string): Promise<AuthResult> {
  if (!account.trim()) return { ok: false, message: 'Vui lòng nhập tên tài khoản.' };
  if (password.length < 6) return { ok: false, message: 'Mật khẩu cần ít nhất 6 ký tự.' };
  if (password !== confirm) return { ok: false, message: 'Mật khẩu nhập lại chưa khớp.' };
  await delay(950);
  return { ok: false, message: 'Chưa kết nối máy chủ đăng ký — đây là bản trình diễn web.' };
}
