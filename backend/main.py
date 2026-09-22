"""Download and run TrOCR locally, without a web server.

Examples:
    python main.py --download-only
    python main.py path/to/handwriting.jpg
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any

MODEL_ID = "microsoft/trocr-small-handwritten"
MODEL_DIRECTORY = Path(__file__).resolve().parent / "models" / "trocr-small-handwritten"


def download_model(force_download: bool = False) -> Path:
    """Store all model files in this project instead of the Hugging Face cache."""
    from huggingface_hub import snapshot_download

    print(f"Downloading {MODEL_ID} to {MODEL_DIRECTORY} ...", file=sys.stderr)
    snapshot_download(
        repo_id=MODEL_ID,
        local_dir=MODEL_DIRECTORY,
        force_download=force_download,
    )
    print("Model download complete.", file=sys.stderr)
    return MODEL_DIRECTORY


def model_is_downloaded() -> bool:
    # These files are required by the processor and model loaders.
    return (MODEL_DIRECTORY / "config.json").is_file() and any(
        (MODEL_DIRECTORY / filename).is_file()
        for filename in ("model.safetensors", "pytorch_model.bin")
    )


def load_model() -> tuple[Any, Any, Any]:
    import torch
    from transformers import TrOCRProcessor, VisionEncoderDecoderModel

    if not model_is_downloaded():
        download_model()

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    processor = TrOCRProcessor.from_pretrained(MODEL_DIRECTORY, local_files_only=True)
    model = VisionEncoderDecoderModel.from_pretrained(
        MODEL_DIRECTORY,
        local_files_only=True,
    ).to(device)
    model.eval()
    return processor, model, device


def extract_text(
    image_path: Path,
    processor: Any,
    model: Any,
    device: Any,
) -> str:
    import torch
    from PIL import Image, UnidentifiedImageError

    try:
        with Image.open(image_path) as source:
            image = source.convert("RGB")
    except (FileNotFoundError, UnidentifiedImageError) as error:
        raise ValueError(f"Cannot read image: {image_path}") from error

    with torch.inference_mode():
        pixel_values = processor(images=image, return_tensors="pt").pixel_values.to(device)
        generated_ids = model.generate(pixel_values)
    return processor.batch_decode(generated_ids, skip_special_tokens=True)[0]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the locally stored TrOCR model.")
    parser.add_argument("image", nargs="?", type=Path, help="Image to transcribe")
    parser.add_argument(
        "--download-only",
        action="store_true",
        help="Download the model to backend/models and exit",
    )
    parser.add_argument(
        "--force-download",
        action="store_true",
        help="Download the model again even if local files already exist",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.download_only or args.force_download:
        download_model(force_download=args.force_download)
        return
    if args.image is None:
        raise SystemExit("Provide an image path, or use --download-only.")

    processor, model, device = load_model()
    print(extract_text(args.image, processor, model, device))


if __name__ == "__main__":
    main()
