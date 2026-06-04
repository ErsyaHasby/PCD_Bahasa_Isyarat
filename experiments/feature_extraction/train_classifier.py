"""
=======================================================================
EKSPERIMEN: Training Classifier untuk BISINDO A-Z
=======================================================================
Tujuan: Latih model SVM/RandomForest/KNN dari dataset landmarks
Evaluasi: Confusion matrix + akurasi per kelas
Output: Model terbaik (.pkl) + report evaluasi
=======================================================================
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.svm import SVC
from sklearn.ensemble import RandomForestClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
import joblib
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

# Konfigurasi paths
DATASET_CSV = Path("experiments/feature_extraction/dataset_landmarks.csv")
OUTPUT_DIR = Path("experiments/feature_extraction/models")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def load_and_preprocess_data():
    """
    Load dataset landmarks dan preprocessing.
    
    Returns:
        X_train, X_val, X_test: features split
        y_train, y_val, y_test: labels split
        label_encoder: LabelEncoder object
    """
    print("Loading dataset...")
    df = pd.read_csv(DATASET_CSV)
    
    # Pisahkan features dan label
    X = df.drop('label', axis=1).values
    y = df['label'].values
    
    # Encode label A-Z ke 0-25
    label_encoder = LabelEncoder()
    y_encoded = label_encoder.fit_transform(y)
    
    print(f"Total samples: {len(X)}")
    print(f"Features: {X.shape[1]}")
    print(f"Classes: {len(label_encoder.classes_)}")
    
    # Split: 70% train, 15% validation, 15% test
    X_train, X_temp, y_train, y_temp = train_test_split(
        X, y_encoded, test_size=0.3, random_state=42, stratify=y_encoded
    )
    X_val, X_test, y_val, y_test = train_test_split(
        X_temp, y_temp, test_size=0.5, random_state=42, stratify=y_temp
    )
    
    print(f"\nSplit:")
    print(f"  Train: {len(X_train)} samples")
    print(f"  Val:   {len(X_val)} samples")
    print(f"  Test:  {len(X_test)} samples")
    
    return X_train, X_val, X_test, y_train, y_val, y_test, label_encoder


def train_svm(X_train, y_train):
    """Train SVM classifier dengan RBF kernel."""
    print("\nTraining SVM...")
    svm = SVC(kernel='rbf', C=10, gamma='scale', random_state=42)
    svm.fit(X_train, y_train)
    return svm


def train_random_forest(X_train, y_train):
    """Train Random Forest classifier."""
    print("\nTraining Random Forest...")
    rf = RandomForestClassifier(
        n_estimators=100, 
        max_depth=20,
        min_samples_split=5,
        random_state=42,
        n_jobs=-1
    )
    rf.fit(X_train, y_train)
    return rf


def train_knn(X_train, y_train):
    """Train KNN classifier."""
    print("\nTraining KNN...")
    knn = KNeighborsClassifier(n_neighbors=5, n_jobs=-1)
    knn.fit(X_train, y_train)
    return knn


def evaluate_model(model, X_val, y_val, model_name, label_encoder):
    """
    Evaluasi model dan print classification report.
    
    Returns:
        accuracy: akurasi model
    """
    print(f"\n{'='*60}")
    print(f"Evaluasi {model_name}")
    print(f"{'='*60}")
    
    y_pred = model.predict(X_val)
    accuracy = accuracy_score(y_val, y_pred)
    
    # Classification report
    print(f"\nAccuracy: {accuracy:.4f}")
    print("\nClassification Report:")
    print(classification_report(
        y_val, y_pred, 
        target_names=label_encoder.classes_,
        digits=4
    ))
    
    return accuracy


def plot_confusion_matrix(y_true, y_pred, label_encoder, model_name, save_path):
    """
    Plot dan simpan confusion matrix.
    """
    cm = confusion_matrix(y_true, y_pred)
    
    plt.figure(figsize=(12, 10))
    sns.heatmap(
        cm, 
        annot=True, 
        fmt='d', 
        cmap='Blues',
        xticklabels=label_encoder.classes_,
        yticklabels=label_encoder.classes_
    )
    plt.title(f'Confusion Matrix - {model_name}', fontsize=14, fontweight='bold')
    plt.xlabel('Predicted Label', fontsize=12)
    plt.ylabel('True Label', fontsize=12)
    plt.tight_layout()
    plt.savefig(save_path, dpi=150, bbox_inches='tight')
    print(f"Confusion matrix saved: {save_path}")
    plt.close()


def main():
    print("╔══════════════════════════════════════════════════════════════════╗")
    print("║  Training Classifier BISINDO A-Z                                 ║")
    print("╚══════════════════════════════════════════════════════════════════╝\n")
    
    # Load dan preprocess data
    X_train, X_val, X_test, y_train, y_val, y_test, label_encoder = load_and_preprocess_data()
    
    # Train models
    models = {}
    accuracies = {}
    
    # SVM
    svm_model = train_svm(X_train, y_train)
    models['SVM'] = svm_model
    accuracies['SVM'] = evaluate_model(svm_model, X_val, y_val, 'SVM', label_encoder)
    
    # Random Forest
    rf_model = train_random_forest(X_train, y_train)
    models['RandomForest'] = rf_model
    accuracies['RandomForest'] = evaluate_model(rf_model, X_val, y_val, 'Random Forest', label_encoder)
    
    # KNN
    knn_model = train_knn(X_train, y_train)
    models['KNN'] = knn_model
    accuracies['KNN'] = evaluate_model(knn_model, X_val, y_val, 'KNN', label_encoder)
    
    # Pilih model terbaik
    print(f"\n{'='*60}")
    print("Perbandingan Akurasi (Validation Set)")
    print(f"{'='*60}")
    for model_name, acc in accuracies.items():
        print(f"{model_name:15s}: {acc:.4f}")
    
    best_model_name = max(accuracies, key=accuracies.get)
    best_model = models[best_model_name]
    best_accuracy = accuracies[best_model_name]
    
    print(f"\nModel terbaik: {best_model_name} dengan akurasi {best_accuracy:.4f}")
    
    # Evaluasi final pada test set
    print(f"\n{'='*60}")
    print(f"Evaluasi Final pada Test Set - {best_model_name}")
    print(f"{'='*60}")
    y_test_pred = best_model.predict(X_test)
    test_accuracy = accuracy_score(y_test, y_test_pred)
    print(f"\nTest Accuracy: {test_accuracy:.4f}")
    print("\nClassification Report (Test):")
    print(classification_report(
        y_test, y_test_pred,
        target_names=label_encoder.classes_,
        digits=4
    ))
    
    # Plot confusion matrix untuk model terbaik
    plot_confusion_matrix(
        y_test, y_test_pred, label_encoder,
        f"{best_model_name} (Test)",
        OUTPUT_DIR / f"confusion_matrix_{best_model_name.lower()}.png"
    )
    
    # Simpan model terbaik
    model_path = OUTPUT_DIR / f"best_model_{best_model_name.lower()}.pkl"
    joblib.dump(best_model, model_path)
    print(f"\nModel terbaik disimpan: {model_path}")
    
    # Simpan label encoder
    encoder_path = OUTPUT_DIR / "label_encoder.pkl"
    joblib.dump(label_encoder, encoder_path)
    print(f"Label encoder disimpan: {encoder_path}")
    
    print(f"\n✓ Training selesai!")
    print(f"  - Model terbaik: {best_model_name}")
    print(f"  - Test accuracy: {test_accuracy:.4f}")
    print(f"  - Model path: {model_path}")


if __name__ == "__main__":
    main()
