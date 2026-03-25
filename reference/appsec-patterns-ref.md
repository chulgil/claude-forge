# AppSec 패턴 레퍼런스

> security-reviewer 에이전트 및 /security-review 커맨드의 다국어 보안 패턴 참조 문서
> 출처: [appsec-guardian](https://gist.github.com/agentsoflearning/1bf9487d66ee4aca48a899a47be41e25) + CWE 매핑 추가

---

## 1. 파일 리스크 분류

변경 파일을 리스크 수준별로 분류하여 분석 깊이를 결정한다.

| 리스크 | 대상 패턴 | 분석 깊이 |
|--------|-----------|-----------|
| **HIGH** | auth, login, session, token, jwt, oauth, password, payment, crypto, encrypt, hash, admin | Full CWE + STRIDE |
| **MEDIUM** | api/, route, middleware, config, upload, download, redirect, .env | CWE Top 10 |
| **LOW** | docs/, test/, static/, README, CHANGELOG, .md, .txt | 시크릿 스캔만 |

---

## 2. OWASP Top 10 → CWE 매핑 (다국어 예제)

### A01: Broken Access Control (CWE-862, CWE-269)

**Python**
```python
# ❌ CWE-862: IDOR - 소유권 검증 누락
@app.route('/document/<doc_id>')
def get_document(doc_id):
    doc = Document.query.get(doc_id)
    return doc.content  # 누구나 접근 가능

# ✅ 소유권 검증
@app.route('/document/<doc_id>')
@login_required
def get_document(doc_id):
    doc = Document.query.get_or_404(doc_id)
    if doc.owner_id != current_user.id:
        abort(403)
    return doc.content
```

**JavaScript**
```javascript
// ❌ CWE-862: 인가 없는 삭제
app.delete('/users/:id', async (req, res) => {
  await User.deleteOne({ _id: req.params.id })
})

// ✅ 인가 검증
app.delete('/users/:id', authMiddleware, async (req, res) => {
  if (req.user.id !== req.params.id && !req.user.isAdmin) {
    return res.status(403).json({ error: 'Forbidden' })
  }
  await User.deleteOne({ _id: req.params.id })
})
```

### A02: Cryptographic Failures (CWE-327, CWE-798)

**Python**
```python
# ❌ CWE-327: 약한 해시 (비밀번호용)
import hashlib
password_hash = hashlib.md5(password.encode()).hexdigest()
password_hash = hashlib.sha256(password.encode()).hexdigest()  # 비밀번호용으로 부적합

# ✅ bcrypt/argon2 사용
import bcrypt
password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt(rounds=12))

from argon2 import PasswordHasher
ph = PasswordHasher()
password_hash = ph.hash(password)
```

**JavaScript**
```javascript
// ❌ CWE-327: 약한 해시
const hash = crypto.createHash('md5').update(password).digest('hex')

// ✅ bcrypt 사용
const bcrypt = require('bcrypt')
const hash = await bcrypt.hash(password, 12)
```

**Java**
```java
// ❌ CWE-327
MessageDigest md = MessageDigest.getInstance("MD5");

// ✅ BCrypt 사용
BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
String hash = encoder.encode(password);
```

**Go**
```go
// ❌ CWE-327
h := md5.Sum([]byte(password))

// ✅ bcrypt 사용
hash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
```

### A03: Injection (CWE-89, CWE-78, CWE-79)

**SQL Injection (CWE-89)**
```python
# ❌ 문자열 연결
query = f"SELECT * FROM users WHERE email = '{email}'"
cursor.execute(query)

# ✅ 파라미터화 쿼리
cursor.execute("SELECT * FROM users WHERE email = ?", (email,))
user = User.query.filter_by(email=email).first()
```

```javascript
// ❌ 템플릿 리터럴
const result = await db.query(`SELECT * FROM users WHERE id = '${id}'`)

// ✅ 파라미터화 쿼리
const result = await db.query('SELECT * FROM users WHERE id = $1', [id])
```

```java
// ❌ Statement
Statement stmt = conn.createStatement();
stmt.executeQuery("SELECT * FROM users WHERE id = " + userId);

// ✅ PreparedStatement
PreparedStatement pstmt = conn.prepareStatement("SELECT * FROM users WHERE id = ?");
pstmt.setString(1, userId);
```

```go
// ❌ 문자열 연결
db.Query("SELECT * FROM users WHERE id = " + id)

// ✅ 파라미터화
db.Query("SELECT * FROM users WHERE id = $1", id)
```

**Command Injection (CWE-78)**
```python
# ❌ shell=True + 사용자 입력
subprocess.call(f"ping {user_input}", shell=True)
os.system(f"ping {user_input}")

# ✅ 인자 리스트, shell=False
subprocess.run(["ping", "-c", "1", user_input], shell=False, capture_output=True)
```

```javascript
// ❌ exec (shell 사용)
const { exec } = require('child_process')
exec(`ping ${userInput}`)

// ✅ execFile (shell 미사용)
const { execFile } = require('child_process')
execFile('ping', ['-c', '1', userInput])
```

**XSS (CWE-79)**
```javascript
// ❌ innerHTML
element.innerHTML = userInput
// ❌ dangerouslySetInnerHTML
<div dangerouslySetInnerHTML={{ __html: userInput }} />

// ✅ textContent
element.textContent = userInput
// ✅ DOMPurify
import DOMPurify from 'dompurify'
const clean = DOMPurify.sanitize(userInput)
// ✅ React 자동 이스케이프
<div>{userInput}</div>
```

### A04: Insecure Design (CWE-287, CWE-306)

검토 항목:
- 인증 엔드포인트 Rate limiting 적용 여부
- 로그인 실패 시 계정 잠금 로직
- 비밀번호 재설정 토큰 만료 시간
- CAPTCHA 또는 anti-automation 조치

### A05: Security Misconfiguration (CWE-276)

```python
# ❌ 프로덕션 디버그 모드
DEBUG = True
app.debug = True

# ❌ 에러 스택트레이스 노출
@app.errorhandler(500)
def error(e):
    return str(e), 500

# ✅ 프로덕션 설정
DEBUG = False
@app.errorhandler(500)
def error(e):
    logger.error(f"Error: {e}")
    return "Internal server error", 500
```

```javascript
// ❌ 과도한 CORS
app.use(cors({ origin: '*' }))

// ✅ 명시적 origin
app.use(cors({
  origin: ['https://trusted-domain.com'],
  credentials: true
}))
```

### A07: Auth Failures (CWE-287)

```javascript
// ❌ CWE-287: JWT 검증 없음
const decoded = jwt.decode(token)  // 서명 검증 안 함!

// ❌ algorithm 'none' 허용
jwt.sign(payload, null, { algorithm: 'none' })

// ✅ 올바른 JWT 검증
const decoded = jwt.verify(token, secret, {
  algorithms: ['HS256'],
  maxAge: '1h'
})
```

```javascript
// ❌ 쿠키 보안 미설정
res.cookie('sessionId', value)

// ✅ 보안 쿠키
res.cookie('sessionId', value, {
  httpOnly: true,
  secure: true,
  sameSite: 'strict',
  maxAge: 3600000
})
```

### A08: Data Integrity (CWE-502)

```python
# ❌ CWE-502: 안전하지 않은 역직렬화
import pickle
data = pickle.loads(user_input)  # RCE 위험!

import yaml
config = yaml.load(user_input)  # RCE 위험!

# ✅ 안전한 대안
import json
data = json.loads(user_input)

import yaml
config = yaml.safe_load(user_input)
```

### A10: SSRF (CWE-918)

```python
# ❌ 검증 없는 URL
response = requests.get(user_url)

# ✅ URL 검증
from urllib.parse import urlparse
allowed_hosts = ['api.trusted-service.com']
parsed = urlparse(user_url)
if parsed.scheme not in ['http', 'https']:
    raise ValueError("Invalid URL scheme")
if parsed.hostname not in allowed_hosts:
    raise ValueError("Host not allowed")
response = requests.get(user_url)
```

---

## 3. 언어별 위험 함수 레퍼런스

### Python
| 위험도 | 함수 | 위험 | 대안 |
|--------|------|------|------|
| CRITICAL | `eval()`, `exec()`, `compile()` | 코드 실행 | AST 파서, 제한된 평가기 |
| CRITICAL | `os.system()` | 명령 실행 | `subprocess.run(shell=False)` |
| CRITICAL | `subprocess(shell=True)` | 셸 인젝션 | `shell=False` + 인자 리스트 |
| CRITICAL | `pickle.loads()` | RCE | `json.loads()` |
| CRITICAL | `yaml.load()` | RCE | `yaml.safe_load()` |
| HIGH | `open()` 미검증 | 경로 순회 | `pathlib` + 경로 검증 |

### JavaScript/Node.js
| 위험도 | 함수 | 위험 | 대안 |
|--------|------|------|------|
| CRITICAL | `eval()` | 코드 실행 | `JSON.parse()`, 전용 파서 |
| CRITICAL | `new Function()` | 코드 실행 | 정적 함수 |
| CRITICAL | `child_process.exec()` | 명령 실행 | `execFile()` |
| HIGH | `innerHTML` | XSS | `textContent` |
| HIGH | `dangerouslySetInnerHTML` | XSS | DOMPurify |
| HIGH | `document.write()` | XSS | DOM API |

### Java
| 위험도 | 함수 | 위험 | 대안 |
|--------|------|------|------|
| CRITICAL | `Runtime.exec()` | 명령 실행 | ProcessBuilder + 검증 |
| CRITICAL | `ScriptEngine.eval()` | 코드 실행 | 제한된 평가기 |
| CRITICAL | `ObjectInputStream.readObject()` | RCE | JSON/검증된 역직렬화 |
| HIGH | `Statement` (SQL) | SQL 인젝션 | `PreparedStatement` |

### Go
| 위험도 | 함수 | 위험 | 대안 |
|--------|------|------|------|
| CRITICAL | `exec.Command` + 사용자 입력 | 명령 실행 | 입력 검증 + 허용 목록 |
| HIGH | `template.HTML` 미검증 | XSS | `template.HTMLEscapeString` |
| HIGH | SQL 문자열 연결 | SQL 인젝션 | `db.Query($1, arg)` |
| HIGH | `os.Open` 미검증 | 경로 순회 | `filepath.Clean` + 검증 |

---

## 4. 설정 감사 패턴

### Docker 보안

```dockerfile
# ❌ root 사용자 실행
FROM node:16
WORKDIR /app
COPY . .
RUN npm install
CMD ["npm", "start"]

# ✅ 비root 사용자
FROM node:16
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN useradd -r -u 1001 appuser
USER appuser
CMD ["node", "server.js"]
```

### TLS 설정

```nginx
# ❌ 약한 TLS
ssl_protocols TLSv1 TLSv1.1;
ssl_ciphers 'ALL';

# ✅ 강한 TLS
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
ssl_prefer_server_ciphers on;
```

### 보안 헤더

```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "DENY" always;
add_header Content-Security-Policy "default-src 'self'" always;
```

---

## 5. 시크릿 감지 패턴

### 정규식 패턴

| 시크릿 유형 | 패턴 |
|-------------|------|
| AWS Access Key | `(A3T[A-Z0-9]\|AKIA\|AGPA\|AIDA\|AROA\|AIPA\|ANPA\|ANVA\|ASIA)[A-Z0-9]{16}` |
| AWS Secret Key | `(?i)aws(.{0,20})?['"][0-9a-zA-Z/+]{40}['"]` |
| Google API Key | `AIza[0-9A-Za-z-_]{35}` |
| GitHub Token | `gh[pousr]_[A-Za-z0-9_]{36,255}` |
| Slack Token | `xox[baprs]-[0-9]{10,13}-[0-9]{10,13}-[a-zA-Z0-9]{24,32}` |
| Stripe Key | `(?i)(sk\|pk)_(test\|live)_[0-9a-zA-Z]{24,}` |
| JWT | `eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*` |
| Private Key | `-----BEGIN (RSA \|EC \|OPENSSH \|DSA )?PRIVATE KEY-----` |
| DB URL | `(?i)(mysql\|postgresql\|mongodb\|redis)://[^\s]+:[^\s]+@` |

### Shannon 엔트로피 분석

패턴 매칭으로 잡히지 않는 미지의 시크릿 형식을 탐지한다.

```python
import math
from collections import Counter

def shannon_entropy(data):
    if not data:
        return 0
    entropy = 0
    for count in Counter(data).values():
        p = count / len(data)
        entropy -= p * math.log2(p)
    return entropy

# 판단 기준:
# - 문자열 길이 >= 20
# - 엔트로피 > 4.5 → 높은 무작위성, 시크릿일 가능성
# - 변수명이 secret/key/token/password 등일 때만 적용
```

### 화이트리스트 (오탐 방지)

- `.env.example`, `.env.sample` 내의 값
- `YOUR_KEY_HERE`, `XXXXXXXX` 같은 플레이스홀더
- `example.com`, `test@example.com`
- 테스트 파일 내의 `password123`

---

## 6. 파일 업로드 보안 (CWE-434)

```python
# ❌ 검증 없는 업로드
@app.route('/upload', methods=['POST'])
def upload():
    file = request.files['file']
    file.save(f'/uploads/{file.filename}')  # 경로 순회 위험

# ✅ 안전한 업로드
from werkzeug.utils import secure_filename
from pathlib import Path
import uuid

UPLOAD_DIR = Path('/var/uploads')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'pdf'}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB

@app.route('/upload', methods=['POST'])
def upload():
    file = request.files.get('file')
    if not file:
        return "No file", 400

    ext = file.filename.rsplit('.', 1)[-1].lower() if '.' in file.filename else ''
    if ext not in ALLOWED_EXTENSIONS:
        return "File type not allowed", 400

    filename = f"{uuid.uuid4()}_{secure_filename(file.filename)}"

    file.seek(0, 2)
    if file.tell() > MAX_FILE_SIZE:
        return "File too large", 400
    file.seek(0)

    file.save(UPLOAD_DIR / filename)
    return "Uploaded", 200
```
