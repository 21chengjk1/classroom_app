import { useEffect, useState, type FormEvent } from "react";
import { Link } from "react-router-dom";
import { ApiError, fetchCourses, joinCourseByCode } from "../api/client";
import { useAuth } from "../context/AuthContext";
import type { Course } from "../types/api";

export function CoursesPage() {
  const { user } = useAuth();
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [joinCode, setJoinCode] = useState("");
  const [joining, setJoining] = useState(false);
  const [joinError, setJoinError] = useState<string | null>(null);
  const [joinSuccess, setJoinSuccess] = useState<string | null>(null);

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

  const handleJoin = async (e: FormEvent) => {
    e.preventDefault();
    setJoinError(null);
    setJoinSuccess(null);
    setJoining(true);

    try {
      const joinedCourse = await joinCourseByCode(joinCode);
      setCourses((prev) => [joinedCourse, ...prev.filter((c) => c.id !== joinedCourse.id)]);
      setJoinCode("");
      setJoinSuccess(`Joined "${joinedCourse.title}"!`);
    } catch (err) {
      setJoinError(err instanceof ApiError ? err.message : "Failed to join course.");
    } finally {
      setJoining(false);
    }
  };

  return (
    <section>
      <div className="page-header">
        <div>
          <h1>My Courses</h1>
          <p className="muted">
            {user?.can_manage_courses
              ? "Courses you teach or have joined."
              : "Courses you are enrolled in."}
          </p>
        </div>

        {user?.can_manage_courses && (
          <Link to="/courses/new" className="btn btn-primary">
            + New course
          </Link>
        )}
      </div>

      <form onSubmit={handleJoin} className="join-bar">
        <label htmlFor="join-code" className="join-bar-label">
          Join a class
        </label>
        <input
          id="join-code"
          type="text"
          value={joinCode}
          onChange={(e) => setJoinCode(e.target.value.toUpperCase())}
          placeholder="Enter class code (e.g. ABC123)"
          maxLength={12}
          required
        />
        <button type="submit" className="btn btn-primary" disabled={joining}>
          {joining ? "Joining..." : "Join"}
        </button>
      </form>

      {joinError && <div className="alert alert-error">{joinError}</div>}
      {joinSuccess && <div className="alert alert-success">{joinSuccess}</div>}
      {error && <div className="alert alert-error">{error}</div>}

      {loading ? (
        <p className="status-text">Loading courses...</p>
      ) : courses.length === 0 ? (
        <div className="empty-state">
          <p>
            {user?.can_manage_courses
              ? "You don't have any courses yet. Create one or join with a class code."
              : "You aren't enrolled in any courses yet. Ask your teacher for a class code to join."}
          </p>
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

              {course.join_code && (
                <div className="join-code-inline">
                  <span className="muted">Class code:</span>
                  <code className="code-pill">{course.join_code}</code>
                </div>
              )}

              <div className="course-card-footer">
                <span className="muted">
                  {course.instructor?.email ?? "Unknown"} · {course.student_count}{" "}
                  {course.student_count === 1 ? "student" : "students"}
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
