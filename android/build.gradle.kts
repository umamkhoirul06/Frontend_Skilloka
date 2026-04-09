allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// --- ULTIMATE FIX: Bypass Hardcode Java 1.8 pada Plugin Lama ---
subprojects {
    afterEvaluate {
        // 1. Paksa target Java 17 langsung ke dalam 'BaseExtension' Android
        project.extensions.findByType<com.android.build.gradle.BaseExtension>()?.let { ext ->
            ext.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }

        // 2. Tambahkan namespace jika kosong (mencegah error namespace)
        project.extensions.findByType<com.android.build.gradle.LibraryExtension>()?.let { ext ->
            if (ext.namespace == null) {
                ext.namespace = project.group.toString()
            }
        }

        // 3. Kunci Task Kompilasi Java ke versi 17
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
        }

        // 4. Kunci Task Kompilasi Kotlin ke versi 17
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = JavaVersion.VERSION_17.toString()
            }
        }
    }
}
// ---------------------------------------------------------------

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}