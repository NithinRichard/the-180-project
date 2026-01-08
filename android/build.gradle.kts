allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Inject SDK versions into all plugins using standard Flutter patterns
    project.ext.set("compileSdkVersion", 36)
    project.ext.set("targetSdkVersion", 36)
    project.ext.set("minSdkVersion", 21)
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val subproject = this
    subproject.layout.buildDirectory.value(newBuildDir.dir(subproject.name))
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    project.configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.12.0")
            force("androidx.core:core-ktx:1.12.0")
            force("androidx.annotation:annotation:1.8.0")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
