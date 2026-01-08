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
    project.configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.12.0")
            force("androidx.core:core-ktx:1.12.0")
            force("androidx.annotation:annotation:1.8.0")
        }
    }
}

// Safely override SDK versions for all Android plugins
subprojects {
    afterEvaluate {
        val project = this
        if (project.extensions.findByType(com.android.build.gradle.BaseExtension::class.java) != null) {
            val android = project.extensions.getByType(com.android.build.gradle.BaseExtension::class.java)
            android.compileSdkVersion(36)
            android.defaultConfig.targetSdkVersion(36)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
