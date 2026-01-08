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

// Ensure all subprojects (plugins) use the same SDK versions
subprojects {
    project.plugins.configureEach {
        if (this.class.name.contains("AndroidBasePlugin") || this is com.android.build.gradle.BasePlugin) {
            val android = project.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
            android?.apply {
                compileSdkVersion(36)
                defaultConfig {
                    targetSdkVersion(36)
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
