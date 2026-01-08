allprojects {
    repositories {
        google()
        mavenCentral()
    }
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
