import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Inject SDK versions into all plugins using standard Flutter patterns
    // This is the safest way to override SDKs without causing lifecycle or syntax errors
    // Using extra properties for Kotlin DSL compatibility
    extra["compileSdkVersion"] = 36
    extra["targetSdkVersion"] = 36
    extra["minSdkVersion"] = 21
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Force specific versions project-wide to resolve lStar resource error
subprojects {
    project.configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.12.0")
            force("androidx.core:core-ktx:1.12.0")
            force("androidx.annotation:annotation:1.8.0")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
