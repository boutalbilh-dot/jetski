allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

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

// Workaround for legacy Flutter plugins (e.g. flutter_bluetooth_serial 0.4.0)
// that don't declare a `namespace` in their android/build.gradle. AGP 8+
// requires every library to have one — inject a fallback after evaluation.
subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            project.extensions.findByType(
                com.android.build.gradle.LibraryExtension::class.java,
            )?.apply {
                if (namespace.isNullOrEmpty()) {
                    namespace = "com.legacy." + project.name.replace("-", "_")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
