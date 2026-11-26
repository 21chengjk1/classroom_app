import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import {
  ApiError,
  deleteCourse,
  fetchCourse,
  unenrollFromCourse,
} from "../api/client";
import type { Course } from "../types/api";

export function CourseDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [course, setCourse] = useState<Course | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [leaving, setLeaving] = useState(false);
  const [copied, setCopied] = useState(false);

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

  const handleLeave = async () => {
    if (!course || !window.confirm(`Leave "${course.title}"?`)) return;
    setLeaving(true);
    setError(null);

    try {
      await unenrollFromCourse(course.id);
      navigate("/courses");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to leave course.");
      setLeaving(false);
    }
  };

  const handleCopyCode = async () => {
    if (!course?.join_code) return;
    await navigator.clipboard.writeText(course.join_code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
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

        <div className="detail-actions">
          {course.can_modify ? (
            <>
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
            </>
          ) : (
            <button
              type="button"
              className="btn btn-secondary"
              onClick={handleLeave}
              disabled={leaving}
            >
              {leaving ? "Leaving..." : "Leave course"}
            </button>
          )}
        </div>
      </div>

      {course.join_code && (
        <div className="join-code-box">
          <div>
            <span className="muted">Class join code</span>
            <div className="join-code-value">{course.join_code}</div>
          </div>
          <button type="button" className="btn btn-secondary" onClick={handleCopyCode}>
            {copied ? "Copied!" : "Copy code"}
          </button>
        </div>
      )}

      <div className="detail-body">
        <h3>Description</h3>
        <p>{course.description || "No description provided."}</p>
      </div>

      {course.students && (
        <div className="roster-section">
          <h3>Enrolled Students ({course.students.length})</h3>
          {course.students.length === 0 ? (
            <p className="muted">
              No students enrolled yet. Share the join code above to invite students.
            </p>
          ) : (
            <ul className="roster-list">
              {course.students.map((student) => (
                <li key={student.id}>{student.email}</li>
              ))}
            </ul>
          )}
        </div>
      )}
    </section>
  );
}
