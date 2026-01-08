allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Global dependency resolution to fix lStar
allprojects {
    configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.12.0")
            force("androidx.core:core-ktx:1.12.0")
            force("androidx.annotation:annotation:1.8.0")
        }
    }
}

// Force SDK 35 on all subprojects (plugins) to avoid resource errors
subprojects {
    project.plugins.configureEach {
        if (this is com.android.build.gradle.BasePlugin) {
            val android = project.extensions.getByType(com.android.build.gradle.BaseExtension::class.java)
            android.compileSdkVersion(35)
            android.defaultConfig {
                targetSdkVersion(35)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
