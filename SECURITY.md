# 🔐 Security Policy

## 🛡️ Supported Versions

We only provide security updates for the latest maintained version of **EcoSort by Bao**.

| Version | Supported |
| ------- | --------- |
| 0.5.x   | ✅ Yes     |
| < 0.5.0 | ❌ No      |

> Please make sure you are using the latest version to receive security updates and fixes.

---

## 🚨 Reporting a Vulnerability

**Please DO NOT report security vulnerabilities through public GitHub Issues.**

If you discover a security issue, report it responsibly:

- 📧 **Email:** tiktokthu10@gmail.com
- 📝 **Include:**
    - Description of the vulnerability
    - Steps to reproduce (Proof of Concept if possible)
    - Potential impact

### ⏱️ Response Timeline

- Initial response: within **48 hours**
- Status update: within **3–5 business days**
- Fix timeline: depends on severity

We appreciate responsible disclosure and will work with you to resolve issues quickly.

---

## 📌 Scope

This policy applies to:

- 📱 Mobile application (**EcoSort by Bao**)
- ☁️ Backend services (**Supabase**)
- 🖥️ Web Admin Dashboard

This policy does **not** cover:

- Third-party services (e.g., Google ML Kit, Supabase infrastructure)

---

## 🔐 Security Measures

### 1. Authentication & Authorization

- **Supabase Auth** is used for secure authentication and session management
- **Row Level Security (RLS)** ensures users can only access their own data via `auth.uid()`

---

### 2. Anti-Spam & Data Protection

- Content-addressable storage using hashing
- Each uploaded image is assigned a unique hash to prevent duplication
- Duplicate submissions are automatically blocked or overwritten (upsert)

> ⚠️ Note: Hashing is used for deduplication, not cryptographic security.

---

### 3. Environment & Secrets Security

- API keys (Gemini, Supabase) are **never stored in plain text**
- Secrets are managed using `.env` and encrypted via **Envied**
- Sensitive files are excluded via `.gitignore`

---

### 4. Admin Security

- Restricted access to admin-only operations
- Sensitive actions require elevated privileges
- **Audit logs** are maintained for traceability

---

## 🔒 Privacy

We respect user privacy:

- Only minimal data is collected (e.g., display name, XP for gamification)
- Uploaded images are used solely for:
    - AI model improvement
    - Content moderation

We do **not** collect unnecessary personal information.

---

## ⚖️ Responsible Disclosure

- Please allow reasonable time for fixes before public disclosure
- Do not exploit vulnerabilities beyond necessary proof
- Avoid accessing other users' data

---

## 📢 Security Updates

Security-related changes will be documented in the [CHANGELOG.md](./CHANGELOG.md).

---

## 🙌 Acknowledgements

We appreciate the efforts of security researchers and contributors who help improve the safety of this project.
