allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Plugin subprojects (e.g. :jni) otherwise fall back to AGP's default NDK version and
// trigger a second multi-GB NDK download. Pin them to the same NDK the app uses.
// Must be registered before the evaluationDependsOn block below, which forces evaluation.
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            ext.javaClass.methods
                .firstOrNull { it.name == "setNdkVersion" && it.parameterCount == 1 }
                ?.invoke(ext, "29.0.14206865")
            // Also pin compileSdk: some plugins otherwise resolve to a minor-version
            // platform (android-37.0) that does not match the 'android-37' hash Gradle asks for.
            ext.javaClass.methods
                .firstOrNull { it.name == "setCompileSdkVersion" && it.parameterCount == 1
                               && it.parameterTypes[0] == Int::class.javaPrimitiveType }
                ?.invoke(ext, 36)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
