"""
=======================================================================
EKSPERIMEN: Export Model ke Format Mobile (ONNX)
=======================================================================
Tujuan: Convert scikit-learn SVM model ke ONNX untuk Flutter inference
Output: gesture_model.onnx + labels.json
=======================================================================
"""

import joblib
import numpy as np
from pathlib import Path
import json

# Coba import skl2onnx, jika tidak ada akan fallback ke JSON export
try:
    from skl2onnx import convert_sklearn
    from skl2onnx.common.data_types import FloatTensorType

    ONNX_AVAILABLE = True
except ImportError:
    ONNX_AVAILABLE = False
    print("Warning: skl2onnx tidak terinstall. Export ke JSON saja.")

# Konfigurasi paths
MODEL_PKL = Path("experiments/feature_extraction/models/best_model_svm.pkl")
ENCODER_PKL = Path("experiments/feature_extraction/models/label_encoder.pkl")
OUTPUT_DIR = Path("app/assets/models")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def export_to_onnx(model, label_encoder, output_path):
    """
    Export scikit-learn model ke format ONNX.

    Args:
        model: scikit-learn model
        label_encoder: LabelEncoder object
        output_path: path untuk menyimpan file ONNX
    """
    if not ONNX_AVAILABLE:
        print("ONNX export tidak tersedia (skl2onnx tidak terinstall)")
        return False

    print("Exporting model to ONNX...")

    # Tentukan input type (126 features)
    initial_type = [("float_input", FloatTensorType([None, 126]))]

    # Convert model ke ONNX
    onnx_model = convert_sklearn(model, initial_types=initial_type, target_opset=12)

    # Simpan ONNX model
    with open(output_path, "wb") as f:
        f.write(onnx_model.SerializeToString())

    print(f"✓ ONNX model disimpan: {output_path}")
    return True


def export_to_json(model, label_encoder, output_dir):
    """
    Export model parameters dan labels ke JSON (fallback jika ONNX tidak tersedia).

    Args:
        model: scikit-learn model
        label_encoder: LabelEncoder object
        output_dir: direktori output
    """
    print("Exporting model parameters to JSON...")

    # Export labels
    labels = label_encoder.classes_.tolist()
    labels_path = output_dir / "labels.json"
    with open(labels_path, "w") as f:
        json.dump(labels, f, indent=2)
    print(f"✓ Labels disimpan: {labels_path}")

    # Untuk SVM, export support vectors dan parameters
    if hasattr(model, "support_vectors_"):
        svm_params = {
            "model_type": "SVM",
            "n_support": len(model.support_),
            "n_classes": len(model.classes_),
            "n_features": model.n_features_in_,
            "gamma": model.gamma if hasattr(model, "gamma") else "scale",
            "C": model.C if hasattr(model, "C") else 1.0,
            "classes": model.classes_.tolist(),
            # Note: Support vectors dan weights terlalu besar untuk JSON
            # Untuk produksi, gunakan ONNX atau implementasi inference di native
        }

        params_path = output_dir / "svm_params.json"
        with open(params_path, "w") as f:
            json.dump(svm_params, f, indent=2)
        print(f"✓ SVM parameters disimpan: {params_path}")

    return True


def main():
    print("╔══════════════════════════════════════════════════════════════════╗")
    print("║  Export Model ke Format Mobile                                  ║")
    print("╚══════════════════════════════════════════════════════════════════╝\n")

    # Load model dan label encoder
    print("Loading model and label encoder...")
    model = joblib.load(MODEL_PKL)
    label_encoder = joblib.load(ENCODER_PKL)

    print(f"Model type: {type(model).__name__}")
    print(f"Classes: {label_encoder.classes_}")
    print(
        f"N features: {model.n_features_in_ if hasattr(model, 'n_features_in_') else 'N/A'}"
    )

    # Export ke ONNX (jika tersedia)
    onnx_path = OUTPUT_DIR / "gesture_model.onnx"
    onnx_success = export_to_onnx(model, label_encoder, onnx_path)

    # Export ke JSON (selalu dilakukan untuk labels)
    json_success = export_to_json(model, label_encoder, OUTPUT_DIR)

    print(f"\n✓ Export selesai!")
    if onnx_success:
        print(f"  - ONNX model: {onnx_path}")
    print(f"  - Labels JSON: {OUTPUT_DIR / 'labels.json'}")

    if not ONNX_AVAILABLE:
        print("\n⚠ Catatan: skl2onnx tidak terinstall.")
        print("  Install dengan: pip install skl2onnx")
        print("  Untuk sekarang, hanya labels yang diexport ke JSON.")
        print("  Untuk inference di Flutter, rekomendasi:")
        print("  1. Install skl2onnx dan export ke ONNX (lebih efisien)")
        print("  2. Atau gunakan plugin onnxruntime_flutter")


if __name__ == "__main__":
    main()
