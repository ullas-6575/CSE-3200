## Local TrOCR

The OCR model now runs as a local Python command-line program; FastAPI is not
used. The model is downloaded once to `backend/models/trocr-small-handwritten/`
and is excluded from Git.

```bash
cd backend
python -m venv .venv
source .venv/bin/activate       # Windows: .venv\Scripts\activate
pip install -r requirements.txt
python main.py --download-only
python main.py path/to/handwriting.jpg
```

After the download finishes, OCR loads only from `backend/models`; it does not
need an internet connection. To replace the saved model files, run:

```bash
python main.py --force-download
```

The Flutter desktop app now starts this local Python command directly; it does
not use port 8000 or any HTTP server. Run the app from the project directory
after installing the Python requirements. If the virtual environment Python is
not your default `python` command, launch Flutter with its executable path:

```bash
flutter run -d windows --dart-define=TROCR_PYTHON=C:/full/path/backend/.venv/Scripts/python.exe
```

This local-process setup is supported on Windows, Linux, and macOS. Android,
iOS, and web builds need an on-device OCR implementation instead.
