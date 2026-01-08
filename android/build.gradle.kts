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
    val subproject = this
    subproject.plugins.configureEach {
        if (this is com.android.build.gradle.BasePlugin) {
            val android = subproject.extensions.getByType(com.android.build.gradle.BaseExtension::class.java)
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
