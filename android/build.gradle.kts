allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Global properties that Flutter plugins often use
    project.ext.set("compileSdkVersion", 36)
    project.ext.set("targetSdkVersion", 36)
    project.ext.set("minSdkVersion", 21)
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

// Safely override SDK versions for all Android plugins using standard Flutter patterns
subprojects {
    project.plugins.withId("com.android.application") {
        val android = project.extensions.getByType(com.android.build.gradle.BaseExtension::class.java)
        android.compileSdkVersion(36)
        android.defaultConfig.targetSdkVersion(36)
    }
    project.plugins.withId("com.android.library") {
        val android = project.extensions.getByType(com.android.build.gradle.BaseExtension::class.java)
        android.compileSdkVersion(36)
        android.defaultConfig.targetSdkVersion(36)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
