# TFLite model placeholder
# Letakkan file gesture_model.tflite di sini setelah model selesai dilatih.
#
# Struktur yang diharapkan:
#   assets/models/gesture_model.tflite   <- model utama klasifikasi gestur
#   assets/models/labels.txt             <- daftar label kelas isyarat
#
# Panduan melatih model:
#   1. Kumpulkan dataset BISINDO (min. 500 sampel per kelas)
#   2. Latih dengan TensorFlow/Keras → export ke TFLite
#   3. Optimasi dengan quantization (int8) untuk performa mobile
#   4. Letakkan file .tflite di direktori ini
