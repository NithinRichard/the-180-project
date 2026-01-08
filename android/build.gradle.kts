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
                useVersion("1.12.0")
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    project.plugins.configureEach {
        if (this is com.android.build.gradle.BasePlugin) {
            val android = project.extensions.getByType(com.android.build.gradle.BaseExtension::class.java)
            android.compileSdkVersion(36)
            android.defaultConfig {
                targetSdkVersion(36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
