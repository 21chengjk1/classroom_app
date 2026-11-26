export type UserRole = "student" | "teacher";

export interface User {
  id: number;
  email: string;
  role: UserRole;
  can_manage_courses: boolean;
}

export interface PersonSummary {
  id: number;
  email: string;
}

export interface Course {
  id: number;
  title: string;
  description: string | null;
  join_code: string | null;
  student_count: number;
  created_at: string;
  updated_at: string;
  instructor: PersonSummary | null;
  can_modify: boolean;
  students?: PersonSummary[];
}

export interface CourseInput {
  title: string;
  description: string;
}
