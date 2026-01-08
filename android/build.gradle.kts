allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Global properties often picked up by Flutter plugins
    project.ext.set("compileSdkVersion", 35)
    project.ext.set("targetSdkVersion", 35)
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

// Safely override SDK versions for all Android plugins
subprojects {
    project.plugins.withId("com.android.library") {
        val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
        android.compileSdkVersion(35)
        android.defaultConfig.targetSdkVersion(35)
    }
    project.plugins.withId("com.android.application") {
        val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
        android.compileSdkVersion(35)
        android.defaultConfig.targetSdkVersion(35)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
