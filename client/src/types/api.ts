export type UserRole = "student" | "teacher";

export interface User {
  id: number;
  email: string;
  role: UserRole;
  can_manage_courses: boolean;
}

export interface Instructor {
  id: number;
  email: string;
}

export interface Course {
  id: number;
  title: string;
  description: string | null;
  created_at: string;
  updated_at: string;
  instructor: Instructor | null;
  can_modify: boolean;
}

export interface CourseInput {
  title: string;
  description: string;
}
