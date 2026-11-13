# LiD Koçu — R8 kuralları
-keepattributes SourceFile,LineNumberTable

# ---- WorkManager / Room (1.1.2 açılış çökmesi)
# play-services-ads, WorkManager'ı getirir; WorkManager açılışta (androidx.startup.InitializationProvider)
# Room ile androidx.work.impl.WorkDatabase_Impl sınıfını yansımayla (Class.forName + newInstance) oluşturur.
# R8 tam modu bu sınıfı koddan hiç örneklenmediği için soyutlaştırıp/kurucusunu silince uygulama açılmadan çöküyordu:
#   "Failed to create an instance of androidx.work.impl.WorkDatabase"
# Room veritabanı uygulamaları ve boş kurucuları korunur.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.impl.WorkManagerInitializer { *; }
-keep class * extends androidx.startup.Initializer { <init>(); }
