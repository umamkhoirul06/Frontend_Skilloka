allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// --- Java & Kotlin compatibility ---
subprojects {
    afterEvaluate {
        // 1. Paksa Android compile/target ke Java 17
        project.extensions.findByType<com.android.build.gradle.BaseExtension>()?.let { ext ->
            ext.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }

        // 2. Tambahkan namespace jika belum ada
        project.extensions.findByType<com.android.build.gradle.LibraryExtension>()?.let { ext ->
            if (ext.namespace == null) {
                ext.namespace = project.group.toString()
            }
        }

        // 3. Kompilasi Java menggunakan Java 17
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
        }

        // 4. Kompilasi Kotlin menggunakan JVM 17
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(
                    org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                )
            }
        }
    }
}
// -------------------------------------

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory =
        newBuildDir.dir(project.name)

    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}