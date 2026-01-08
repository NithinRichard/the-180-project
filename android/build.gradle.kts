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
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.core" && (requested.name == "core" || requested.name == "core-ktx")) {
                useVersion("1.8.0")
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    project.plugins.withType<com.android.build.gradle.BasePlugin> {
        val android = project.extensions.getByType<com.android.build.gradle.BaseExtension>()
        android.compileSdkVersion(35)
        android.defaultConfig {
            targetSdkVersion(35)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
