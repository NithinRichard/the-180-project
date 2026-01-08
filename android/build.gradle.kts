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

subprojects {
    project.evaluationDependsOn(":app")
}

// Safely override SDK versions for all Android plugins
subprojects {
    project.plugins.configureEach {
        val plugin = this
        if (plugin::class.java.name.contains("AndroidBasePlugin")) {
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
