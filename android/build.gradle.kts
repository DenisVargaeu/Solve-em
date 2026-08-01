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

// Workaround for a CameraX 1.5.x packaging bug: `camera-core` references
// `androidx.concurrent.futures.CallbackToFutureAdapter` in a public field's
// type annotation but never declares the artifact in its POM. javac then
// fails with "class file for ... not found" when compiling the
// `camera_android_camerax` plugin. Inject the missing artifact onto that
// plugin's compile classpath directly.
// See: https://groups.google.com/a/android.com/g/camerax-developers/c/exNGG7HvrC8
subprojects {
    if (name == "camera_android_camerax") {
        plugins.withId("com.android.library") {
            dependencies {
                add("implementation", "androidx.concurrent:concurrent-futures:1.1.0")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
