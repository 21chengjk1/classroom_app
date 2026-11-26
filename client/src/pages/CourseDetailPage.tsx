import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { ApiError, deleteCourse, fetchCourse } from "../api/client";
import type { Course } from "../types/api";

export function CourseDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [course, setCourse] = useState<Course | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    if (!id) return;

    let cancelled = false;
    fetchCourse(id)
      .then((data) => {
        if (!cancelled) setCourse(data);
      })
      .catch((err) => {
        if (!cancelled) {
          setError(err instanceof ApiError ? err.message : "Failed to load course.");
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [id]);

  const handleDelete = async () => {
    if (!course || !window.confirm(`Delete "${course.title}"?`)) return;
    setDeleting(true);
    setError(null);

    try {
      await deleteCourse(course.id);
      navigate("/courses");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to delete course.");
      setDeleting(false);
    }
  };

  if (loading) {
    return <p className="status-text">Loading course...</p>;
  }

  if (error || !course) {
    return (
      <section>
        <div className="alert alert-error">{error ?? "Course not found."}</div>
        <Link to="/courses" className="text-link">
          ← Back to courses
        </Link>
      </section>
    );
  }

  return (
    <section className="detail-card">
      <Link to="/courses" className="text-link">
        ← Back to courses
      </Link>

      <div className="detail-header">
        <div>
          <h1>{course.title}</h1>
          <p className="muted">
            Instructor: {course.instructor?.email ?? "Unknown"}
          </p>
        </div>

        {course.can_modify && (
          <div className="detail-actions">
            <Link to={`/courses/${course.id}/edit`} className="btn btn-secondary">
              Edit
            </Link>
            <button
              type="button"
              className="btn btn-danger"
              onClick={handleDelete}
              disabled={deleting}
            >
              {deleting ? "Deleting..." : "Delete"}
            </button>
          </div>
        )}
      </div>

      <div className="detail-body">
        <h3>Description</h3>
        <p>{course.description || "No description provided."}</p>
      </div>
    </section>
  );
}
