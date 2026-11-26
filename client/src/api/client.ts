import type { Course, CourseInput, User } from "../types/api";

const API_BASE_URL =
  import.meta.env.VITE_API_URL?.replace(/\/$/, "") || "http://localhost:3000/api/v1";

const TOKEN_STORAGE_KEY = "classroom_jwt";

export function getStoredToken(): string | null {
  return localStorage.getItem(TOKEN_STORAGE_KEY);
}

export function setStoredToken(token: string | null): void {
  if (token) {
    localStorage.setItem(TOKEN_STORAGE_KEY, token);
  } else {
    localStorage.removeItem(TOKEN_STORAGE_KEY);
  }
}

export class ApiError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

interface RequestResult<T> {
  data: T;
  authorizationHeader: string | null;
}

async function apiRequest<T>(
  path: string,
  options: RequestInit = {}
): Promise<RequestResult<T>> {
  const token = getStoredToken();
  const headers = new Headers(options.headers);

  headers.set("Accept", "application/json");
  if (options.body && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }
  if (token) {
    headers.set("Authorization", token);
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers,
  });

  const authorizationHeader = response.headers.get("Authorization");

  if (response.status === 204) {
    return { data: undefined as T, authorizationHeader };
  }

  const text = await response.text();
  const parsed = text ? JSON.parse(text) : null;

  if (!response.ok) {
    const message =
      parsed?.error ||
      (Array.isArray(parsed?.errors) ? parsed.errors.join(", ") : null) ||
      `Request failed (${response.status})`;
    throw new ApiError(message, response.status);
  }

  return { data: parsed as T, authorizationHeader };
}

export async function loginRequest(email: string, password: string): Promise<User> {
  const { data, authorizationHeader } = await apiRequest<{ user: User }>("/login", {
    method: "POST",
    body: JSON.stringify({ user: { email, password } }),
  });

  if (authorizationHeader) {
    setStoredToken(authorizationHeader);
  }

  return data.user;
}

export async function signupRequest(
  email: string,
  password: string,
  passwordConfirmation: string
): Promise<User> {
  const { data, authorizationHeader } = await apiRequest<{ user: User }>("/signup", {
    method: "POST",
    body: JSON.stringify({
      user: {
        email,
        password,
        password_confirmation: passwordConfirmation,
      },
    }),
  });

  if (authorizationHeader) {
    setStoredToken(authorizationHeader);
  }

  return data.user;
}

export async function logoutRequest(): Promise<void> {
  try {
    await apiRequest<{ message: string }>("/logout", { method: "DELETE" });
  } finally {
    setStoredToken(null);
  }
}

export async function fetchCurrentUser(): Promise<User> {
  const { data } = await apiRequest<{ user: User }>("/me");
  return data.user;
}

export async function fetchCourses(): Promise<Course[]> {
  const { data } = await apiRequest<{ courses: Course[] }>("/courses");
  return data.courses;
}

export async function fetchCourse(id: number | string): Promise<Course> {
  const { data } = await apiRequest<{ course: Course }>(`/courses/${id}`);
  return data.course;
}

export async function createCourse(input: CourseInput): Promise<Course> {
  const { data } = await apiRequest<{ course: Course }>("/courses", {
    method: "POST",
    body: JSON.stringify({ course: input }),
  });
  return data.course;
}

export async function updateCourse(
  id: number | string,
  input: CourseInput
): Promise<Course> {
  const { data } = await apiRequest<{ course: Course }>(`/courses/${id}`, {
    method: "PATCH",
    body: JSON.stringify({ course: input }),
  });
  return data.course;
}

export async function deleteCourse(id: number | string): Promise<void> {
  await apiRequest<void>(`/courses/${id}`, { method: "DELETE" });
}

export async function joinCourseByCode(joinCode: string): Promise<Course> {
  const { data } = await apiRequest<{ course: Course }>("/enrollments", {
    method: "POST",
    body: JSON.stringify({ join_code: joinCode }),
  });
  return data.course;
}

export async function unenrollFromCourse(courseId: number | string): Promise<void> {
  await apiRequest<void>(`/enrollments/${courseId}`, { method: "DELETE" });
}
