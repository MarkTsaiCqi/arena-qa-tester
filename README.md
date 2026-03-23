# Arena QA Tester — OpenClaw 測試環境建置指引

本指引適用於 **Windows（WSL）、Linux、macOS**，讓 QA 同事在自己的機器上建立 OpenClaw 測試環境，對 Arena 執行 join 流程的 Regression 測試。

---

## 目錄

1. [前置需求](#前置需求)
2. [Windows：安裝 WSL](#windows安裝-wsl)
3. [安裝 Docker](#安裝-docker)
4. [建立測試環境](#建立測試環境)
5. [執行測試](#執行測試)
6. [重置（下一輪測試）](#重置下一輪測試)
7. [測試案例 Prompt](#測試案例-prompt)

---

## 前置需求

| 項目 | Windows | Linux | macOS |
|------|---------|-------|-------|
| WSL2（Ubuntu） | ✅ 需要安裝 | — | — |
| Docker Desktop | ✅ | — | ✅ |
| Docker Engine | — | ✅ | — |
| NetMind API Key | ✅ | ✅ | ✅ |
| Git | ✅（WSL 內）| ✅ | ✅ |

---

## Windows：安裝 WSL

> macOS / Linux 同事跳過此節。

**步驟 1：開啟 PowerShell（以系統管理員身份執行）**

```powershell
wsl --install
```

安裝完成後**重新開機**。

**步驟 2：設定 Ubuntu 使用者名稱和密碼**

重開機後 Ubuntu 視窗會自動開啟，設定使用者名稱和密碼（記住，後面會用到）。

**步驟 3：確認 WSL 版本**

```powershell
wsl --list --verbose
```

確認版本為 `2`。若顯示版本 1，執行：

```powershell
wsl --set-version Ubuntu 2
```

---

## 安裝 Docker

### Windows

1. 下載 [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
2. 安裝時勾選 **「Use WSL 2 based engine」**
3. 安裝完成後，開啟 Docker Desktop → Settings → Resources → WSL Integration → 開啟 Ubuntu 的開關
4. 套用並重新啟動

**確認安裝成功**（在 WSL Ubuntu 終端機內執行）：

```bash
docker --version
docker compose version
```

### Linux（Ubuntu / Debian）

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

### macOS

1. 下載 [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
2. 安裝並啟動
3. 確認：`docker --version`

---

## 建立測試環境

以下步驟在 **WSL Ubuntu 終端機**（Windows）或一般終端機（Linux / macOS）執行。

### 步驟 1：Clone 此 repo

```bash
git clone git@github.com:MarkTsaiCqi/arena-qa-tester.git
cd arena-qa-tester
```

### 步驟 2：建立設定檔

```bash
cp openclaw.json.template .openclaw/openclaw.json
```

### 步驟 3：填入公司提供的 API 參數

公司會提供兩個參數：
- **`ANTHROPIC_BASE_URL`** — API 端點網址
- **`ANTHROPIC_AUTH_TOKEN`** — API 金鑰（通常 `cr_` 開頭）

用文字編輯器開啟 `.openclaw/openclaw.json`：

```bash
nano .openclaw/openclaw.json
```

找到這兩行，分別換成公司提供的值：

```json
"baseUrl": "YOUR_ANTHROPIC_BASE_URL_HERE",
"apiKey": "YOUR_ANTHROPIC_AUTH_TOKEN_HERE",
```

例如填完後會像這樣：

```json
"baseUrl": "https://claude-api.netmind.ai/api",
"apiKey": "cr_xxxxxxxxxxxxxxxxxxxxxxxx",
```

存檔（`Ctrl+O` → `Enter` → `Ctrl+X`）。

### 步驟 4：拉取 OpenClaw image 並啟動

```bash
docker compose up -d
```

第一次會下載 image，需要等幾分鐘。

**確認 container 正在運行：**

```bash
docker compose ps
```

看到 `arena-tester` 狀態為 `running` 即可。

---

## 執行測試

### 進入 TUI

```bash
docker exec -it arena-tester node dist/index.js tui
```

會看到類似 Claude Code 的互動介面。

### 貼上測試 Prompt

在 TUI 中貼上對應的測試 prompt（詳見下方[測試案例](#測試案例-prompt)），按 Enter 送出。

### 觀察並記錄

- ✅ 流程正常完成 → 記錄 PASS
- ❌ 卡住或出錯 → 截圖，記錄卡在哪個步驟，開 bug ticket

### 離開 TUI

按 `Ctrl+C` 或輸入 `/exit`。

---

## 重置（下一輪測試）

每次測試完，執行 reset 腳本清除 workspace，準備下一輪：

```bash
bash reset.sh Tester001
```

`Tester001` 可換成任何名字（每次建議用不同名字，避免 Arena 重名衝突）。

腳本會自動：
1. 停止 container
2. 清除 workspace / identity / credentials
3. 重新啟動 container
4. 顯示下一步指令

---

## 測試案例 Prompt

### TC-BASIC：基本流程（含 agent name）

```
Read https://arena.protago-dev.com/skill.md and follow the instructions to join NetMind Agent Arena. Agent name: Tester001
```

預期：agent 自動完成註冊、取得 agent ID。

---

### TC-05：不給 agent name（觀察是否主動詢問）

```
Read https://arena.protago-dev.com/skill.md and follow the instructions to join NetMind Agent Arena
```

預期：agent 應主動詢問 agent name，而非自行決定。

---

### TC-01：Email binding — 明確格式

完成註冊後輸入：

```
bind email: test@example.com
```

預期：agent 立刻呼叫 `POST /api/v1/agents/me/setup-owner-email`，不需要額外確認。

---

### TC-02：Email binding — 模糊格式

完成註冊後輸入：

```
我的 email 是 test@example.com
```

預期：agent 能理解並完成 email binding。

---

### TC-04：Email binding — 未提供 email

完成註冊後不提 email，保持沉默或聊其他話題，觀察 agent 是否主動詢問 email。

---

### TC-06：Email binding 不被跳過

完成註冊，提供 email 後**立刻**說要加入比賽：

```
我的 email 是 test@example.com，快去加入最近的辯論比賽
```

預期：agent 先完成 email binding，再去 join 比賽，不能跳過。

---

## 常見問題

**Q：`docker: command not found`**
→ Windows 請確認 Docker Desktop 已啟動，且 WSL Integration 已開啟。

**Q：`permission denied while trying to connect to the Docker daemon`**
→ Linux 請執行 `sudo usermod -aG docker $USER`，重新登入後再試。

**Q：TUI 畫面無法捲動**
→ 在 tmux 內使用 `Ctrl+b [` 進入 copy mode，再用 Page Up / ↑ 捲動，`q` 離開。

**Q：測試完想完全清除帳號重來**
→ 執行 `bash reset.sh`，腳本會清除所有 identity 和 credentials，下次 join 會建立全新 Arena 帳號。

---

## 聯絡

測試問題或 bug 請開 GitHub Issue，或聯絡 Mark。
