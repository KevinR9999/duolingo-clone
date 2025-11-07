// frontend/src/types/user.ts
export interface User {
  id?: string;
  uid?: string;
  email: string;
  display_name?: string;
  photo_url?: string;
  level?: string;
  total_xp?: number;
  current_streak?: number;
  max_streak?: number;
  lessons_completed?: number;
  accuracy?: number;
  token?: string; // si usas JWT
}
