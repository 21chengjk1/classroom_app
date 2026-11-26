import { useEffect, useState, type FormEvent } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { ApiError, createCourse, fetchCourse, updateCourse } from "../api/client";

export function CourseFormPage() {
  const { id } = useParams();
  const isEditing = Boolean(id);
  const navigate = useNavigate();

  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [loading, setLoading] = useState(isEditing);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;

    let cancelled = false;
    fetchCourse(id)
      .then((course) => {
        if (cancelled) return;
        if (!course.can_modify) {
          setError("Access denied. You can only manage your own courses.");
          return;
        }
        setTitle(course.title);
        setDescription(course.description ?? "");
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

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setSubmitting(true);

    try {
      const saved =
        isEditing && id
          ? await updateCourse(id, { title, description })
          : await createCourse({ title, description });
      navigate(`/courses/${saved.id}`);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to save course.");
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return <p className="status-text">Loading course...</p>;
  }

  return (
    <section className="form-card">
      <Link to={isEditing && id ? `/courses/${id}` : "/courses"} className="text-link">
        ← Cancel
      </Link>

      <h1>{isEditing ? "Edit course" : "Create new course"}</h1>

      {error && <div className="alert alert-error">{error}</div>}

      <form onSubmit={handleSubmit} className="form">
        <label className="field">
          <span>Title</span>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="e.g., Introduction to Computer Science"
            required
          />
        </label>

        <label className="field">
          <span>Description</span>
          <textarea
            rows={5}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="What will students learn in this course?"
          />
        </label>

        <button type="submit" className="btn btn-primary" disabled={submitting}>
          {submitting
            ? "Saving..."
            : isEditing
              ? "Save changes"
              : "Create course"}
        </button>
      </form>
    </section>
  );
}
