# Rust Async/Tokio Gotchas — agents.md
Guidance for code-review agents to detect common async/Tokio issues.

---

## 1. Futures Are Lazy
- Creating a future does **not** run it.
- Flag code that expects work to start before `.await`.

---

## 2. Blocking in Async Context
**Never allow inside async code:**
- `std::thread::sleep`
- `std::fs::read`, `std::fs::write`, etc.
- `std::net::TcpStream`
- CPU-heavy loops

**Use instead:**
- `tokio::time::sleep`
- Async I/O types (`tokio::fs`, `tokio::net`)
- `tokio::task::spawn_blocking` for blocking CPU or I/O

---

## 3. Holding Locks Across `.await`
Flag patterns like:

```rust
let guard = mutex.lock().await;
foo().await; // BAD
```
Require dropping the lock before awaiting.

4. Misunderstanding Tokio Tasks

tokio::spawn does not create OS threads.

Flag blocking calls inside spawned tasks.

5. select! Cancels Losing Branches

tokio::select! aborts the futures not chosen.

Ensure cancellation is intended or futures are pinned and reused.

6. Async Traits (async_trait) Allocation

#[async_trait] introduces allocation + dynamic dispatch.

Prefer associated-type futures when performance matters.

7. Long-Running Loops Stall the Executor

Async Rust is cooperative; no preemption.

Flag loops with no .await or no yield_now().await.

8. No Async Drop

Rust cannot do async work inside Drop.

Require explicit async cleanup (e.g. .close().await).

9. Multiple Tokio Runtimes

Flag creation of tokio::runtime::Runtime inside async code.

Programs should have a single runtime.

10. Misunderstanding Task/Handle Cloning

Tokio tasks cannot be cloned.

Flag attempts to duplicate task handles.

11. Using Blocking std I/O in Async Code

Disallow use of:

std::fs

std::net

std::io (blocking)

Require async equivalents:

tokio::fs

tokio::net

12. Pinning Errors

For custom futures/streams:

Ensure correct use of Pin.

Ensure Box::pin if needed.

Ensure no field is “self-moved” across .await.

Recommended Automatic Checks

Agents should automatically detect:

Blocking calls in async functions.

Mutex guards held across .await.
std I/O inside async functions.
Loops missing .await.
Unexpected cancellation in select!.
Tokio runtime creation inside async code.
