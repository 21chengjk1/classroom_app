import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { ApiError, fetchCourses } from "../api/client";
import { useAuth } from "../context/AuthContext";
import type { Course } from "../types/api";

export function CoursesPage() {
  const { user } = useAuth();
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    fetchCourses()
      .then((list) => {
        if (!cancelled) setCourses(list);
      })
      .catch((err) => {
        if (!cancelled) {
          setError(err instanceof ApiError ? err.message : "Failed to load courses.");
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <section>
      <div className="page-header">
        <div>
          <h1>Courses</h1>
          <p className="muted">Browse available classes or manage the ones you teach.</p>
        </div>

        {user?.can_manage_courses && (
          <Link to="/courses/new" className="btn btn-primary">
            + New course
          </Link>
        )}
      </div>

      {error && <div className="alert alert-error">{error}</div>}

      {loading ? (
        <p className="status-text">Loading courses...</p>
      ) : courses.length === 0 ? (
        <div className="empty-state">
          <p>No courses yet.</p>
          {user?.can_manage_courses && (
            <Link to="/courses/new" className="btn btn-primary">
              Create your first course
            </Link>
          )}
        </div>
      ) : (
        <div className="course-grid">
          {courses.map((course) => (
            <article key={course.id} className="course-card">
              <div className="course-card-header">
                <h2>
                  <Link to={`/courses/${course.id}`}>{course.title}</Link>
                </h2>
                {course.can_modify && <span className="owner-badge">Owner</span>}
              </div>

              <p className="course-description">
                {course.description || "No description provided."}
              </p>

              <div className="course-card-footer">
                <span className="muted">
                  Instructor: {course.instructor?.email ?? "Unknown"}
                </span>
                <Link to={`/courses/${course.id}`} className="text-link">
                  Open →
                </Link>
              </div>
            </article>
          ))}
        </div>
      )}
    </section>
  );
}
