import SwiftUI
import SceneKit
import UIKit

struct ContentView: View {
    @Binding var profile: BodyProfile
    @State private var selectedSection: MeasurementSection = .body
    @State private var pose = FigurePose()
    @State private var displayStyle: FigureDisplayStyle = .realistic
    @State private var lightingStyle: FigureLightingStyle = .studio
    @State private var savedPoses: [SavedFigurePose] = []
    @State private var poseName = ""
    @State private var showSavePrompt = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var showExportError = false
    @AppStorage("figureStudio.poseLibrary.v2") private var poseLibraryData: Data = Data()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    FigureViewport(profile: profile, pose: pose,
                                   displayStyle: displayStyle, lightingStyle: lightingStyle)
                        .frame(maxWidth: .infinity)
                        .frame(height: 370)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("FIGURE STUDIO")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.8)
                        Text("女性人体 · 3D 参考")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                    .padding(12)
                }
                .background(Color(red: 0.94, green: 0.95, blue: 0.96))

                HStack(spacing: 10) {
                    Menu {
                        Picker("显示模式", selection: $displayStyle) {
                            ForEach(FigureDisplayStyle.allCases) { style in
                                Text(style.title).tag(style)
                            }
                        }
                    } label: {
                        Label(displayStyle.title, systemImage: "view.3d")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Menu {
                        Picker("灯光", selection: $lightingStyle) {
                            ForEach(FigureLightingStyle.allCases) { style in
                                Text(style.title).tag(style)
                            }
                        }
                    } label: {
                        Label(lightingStyle.title, systemImage: "lightbulb")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        exportHighResolutionImage()
                    } label: {
                        Label("导出", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)

                Picker("工作区", selection: $selectedSection) {
                    ForEach(MeasurementSection.allCases) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                if selectedSection == .pose {
                    PoseControlPanel(
                        pose: $pose,
                        savedPoses: savedPoses,
                        onSave: { showSavePrompt = true },
                        onLoad: { pose = $0.pose },
                        onDelete: deletePose,
                        onPreset: { pose = $0 }
                    )
                } else {
                    List {
                        ForEach(profile.measurements(for: selectedSection)) { item in
                            MeasurementRow(item: item) { newValue in
                                profile.setMeasurement(item.id, value: newValue)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.white)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.white)
            .navigationTitle("人体工坊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("重置") {
                        profile = .defaultProfile
                        pose = FigurePose()
                    }
                }
            }
            .alert("保存姿势", isPresented: $showSavePrompt) {
                TextField("例如：侧身站姿", text: $poseName)
                Button("取消", role: .cancel) { }
                Button("保存") { savePose() }
            } message: {
                Text("姿势会保存在本机，不需要联网。")
            }
            .alert("导出失败", isPresented: $showExportError) {
                Button("好", role: .cancel) { }
            } message: {
                Text("当前设备无法创建高清图像。请稍后重试。")
            }
            .sheet(isPresented: $showShareSheet) {
                if let shareImage {
                    ActivityShareSheet(items: [shareImage])
                }
            }
            .onAppear(perform: restorePoseLibrary)
        }
    }

    private func restorePoseLibrary() {
        if let decoded = try? JSONDecoder().decode([SavedFigurePose].self, from: poseLibraryData) {
            savedPoses = decoded
            return
        }
        // Migrate the original single saved pose into the new named library.
        if let legacyData = UserDefaults.standard.data(forKey: "figureStudio.savedPose"),
           let legacyPose = try? JSONDecoder().decode(FigurePose.self, from: legacyData) {
            savedPoses = [SavedFigurePose(name: "旧版已保存姿势", pose: legacyPose)]
            persistPoseLibrary()
        }
    }

    private func persistPoseLibrary() {
        if let data = try? JSONEncoder().encode(savedPoses) {
            poseLibraryData = data
        }
    }

    private func savePose() {
        let name = poseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        savedPoses.insert(SavedFigurePose(name: name, pose: pose), at: 0)
        poseName = ""
        persistPoseLibrary()
    }

    private func deletePose(_ id: UUID) {
        savedPoses.removeAll { $0.id == id }
        persistPoseLibrary()
    }

    private func exportHighResolutionImage() {
        let exportProfile = profile
        let exportPose = pose
        let exportDisplayStyle = displayStyle
        let exportLightingStyle = lightingStyle
        FemaleBaseMeshLoader.load { loadedScene in
            let scene = FigureSceneBuilder.makeScene(
                profile: exportProfile,
                pose: exportPose,
                displayStyle: exportDisplayStyle,
                lightingStyle: exportLightingStyle
            )
            if let loadedScene {
                let root = SCNNode()
                for child in Array(loadedScene.rootNode.childNodes) {
                    child.removeFromParentNode()
                    root.addChildNode(child)
                }
                FigureSceneBuilder.attachRealisticBaseMesh(
                    root, to: scene, profile: exportProfile, displayStyle: exportDisplayStyle
                )
                FemaleFigureRig(root: root).apply(exportPose)
            }
            guard let image = FigureSceneBuilder.makeSnapshot(scene: scene, width: 1800, height: 2400) else {
                showExportError = true
                return
            }
            shareImage = image
            showShareSheet = true
        }
    }
}

private struct MeasurementRow: View {
    let item: MeasurementItem
    let onChange: (Double) -> Void
    @State private var value: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title).font(.system(size: 15, weight: .medium))
                Spacer()
                Text("\(value, specifier: "%.1f") cm")
                    .font(.system(size: 14, design: .rounded).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: item.range, step: 0.5)
                .tint(Color(red: 0.36, green: 0.58, blue: 0.72))
                .onChange(of: value) { _, newValue in onChange(newValue) }
        }
        .padding(.vertical, 5)
        .onAppear { value = item.value }
        .onChange(of: item.value) { _, newValue in value = newValue }
    }
}

private struct PoseControlPanel: View {
    @Binding var pose: FigurePose
    let savedPoses: [SavedFigurePose]
    let onSave: () -> Void
    let onLoad: (SavedFigurePose) -> Void
    let onDelete: (UUID) -> Void
    let onPreset: (FigurePose) -> Void

    private let fingerNames = ["拇指", "食指", "中指", "无名指", "小指"]

    var body: some View {
        Form {
            Section("姿势库") {
                Picker("肢体控制", selection: $pose.rigMode) {
                    ForEach(FigureRigMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                Menu("载入动作预设") {
                    Button("自然站姿") { onPreset(.natural) }
                    Button("A 字站姿") { onPreset(.aPose) }
                    Button("行走动态") { onPreset(.walking) }
                    Button("坐姿") { onPreset(.sitting) }
                    Button("深蹲") { onPreset(.squat) }
                }
                Button("左右镜像当前姿势", systemImage: "arrow.left.arrow.right") {
                    pose = pose.mirrored()
                }
                Button("保存当前姿势", systemImage: "square.and.arrow.down", action: onSave)
            }

            Section("躯干与头部") {
                AngleControl(title: "躯干前后弯曲", value: $pose.spineFlexionDegrees, range: -45...75)
                AngleControl(title: "躯干侧弯", value: $pose.spineSideBendDegrees, range: -40...40)
                AngleControl(title: "躯干旋转", value: $pose.spineRotationDegrees, range: -75...75)
                AngleControl(title: "头部俯仰", value: $pose.headTiltDegrees, range: -45...45)
                AngleControl(title: "头部转向", value: $pose.headRotationDegrees, range: -85...85)
            }

            armSection(title: "左臂", arm: $pose.leftArm)
            armSection(title: "右臂", arm: $pose.rightArm)

            legSection(title: "左腿", leg: $pose.leftLeg)
            legSection(title: "右腿", leg: $pose.rightLeg)

            if !savedPoses.isEmpty {
                Section("已保存姿势") {
                    ForEach(savedPoses) { entry in
                        HStack {
                            Button {
                                onLoad(entry)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.name).foregroundStyle(.primary)
                                    Text(entry.savedAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button(role: .destructive) {
                                onDelete(entry.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            Section {
                Button("恢复自然站姿", role: .destructive) {
                    pose = FigurePose()
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func armSection(title: String, arm: Binding<ArmPose>) -> some View {
        Section(title + (pose.rigMode == .ik ? " · IK 目标" : " · FK 关节")) {
            if pose.rigMode == .fk {
                AngleControl(title: "肩部前屈", value: arm.shoulderFlexionDegrees, range: -100...150)
                AngleControl(title: "肩部外展", value: arm.shoulderAbductionDegrees, range: -100...100)
                AngleControl(title: "肘部弯曲", value: arm.elbowFlexionDegrees, range: 0...145)
            } else {
                AngleControl(title: "手部横向伸展", value: arm.handReachTargetCM, range: -45...45, suffix: "cm")
                AngleControl(title: "手部垂直抬升", value: arm.handLiftTargetCM, range: -55...75, suffix: "cm")
                AngleControl(title: "手部前后移动", value: arm.handDepthTargetCM, range: -40...40, suffix: "cm")
                Text("IK 会根据手部目标计算肩部和肘部角度，腕部和手指仍可独立控制。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            AngleControl(title: "前臂旋转", value: arm.forearmRotationDegrees, range: -90...90)
            AngleControl(title: "手腕屈伸", value: arm.wristFlexionDegrees, range: -75...75)
            AngleControl(title: "手腕侧偏", value: arm.wristDeviationDegrees, range: -35...35)
            ForEach(0..<5, id: \.self) { index in
                AngleControl(title: "\(fingerNames[index])屈曲",
                             value: arm.fingerCurlDegrees[index], range: 0...95)
            }
        }
    }

    @ViewBuilder
    private func legSection(title: String, leg: Binding<LegPose>) -> some View {
        Section(title + (pose.rigMode == .ik ? " · IK 目标" : " · FK 关节")) {
            if pose.rigMode == .fk {
                AngleControl(title: "髋部前后摆动", value: leg.hipFlexionDegrees, range: -100...120)
                AngleControl(title: "髋部外展", value: leg.hipAbductionDegrees, range: -55...55)
                AngleControl(title: "髋部旋转", value: leg.hipRotationDegrees, range: -55...55)
                AngleControl(title: "膝部弯曲", value: leg.kneeFlexionDegrees, range: 0...140)
            } else {
                AngleControl(title: "脚掌前后目标", value: leg.footForwardTargetCM, range: -55...55, suffix: "cm")
                AngleControl(title: "脚掌抬升目标", value: leg.footLiftTargetCM, range: -30...45, suffix: "cm")
                Text("IK 会根据脚掌目标自动计算髋部和膝部角度。目标会受腿长与关节活动范围限制。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            AngleControl(title: "脚踝屈伸", value: leg.ankleFlexionDegrees, range: -45...45)
            AngleControl(title: "脚趾弯曲", value: leg.toeCurlDegrees, range: 0...60)
        }
    }
}

private struct AngleControl: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var suffix: String = "°"

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value, specifier: "%.0f")\(suffix)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: 1)
        }
        .padding(.vertical, 2)
    }
}

private struct FigureViewport: UIViewRepresentable {
    let profile: BodyProfile
    let pose: FigurePose
    let displayStyle: FigureDisplayStyle
    let lightingStyle: FigureLightingStyle

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        let scene = FigureSceneBuilder.makeScene(profile: profile, pose: pose,
                                                 displayStyle: displayStyle, lightingStyle: lightingStyle)
        view.scene = scene
        view.pointOfView = scene.rootNode.childNode(withName: "figureCamera", recursively: false)
        view.backgroundColor = UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1)
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.rendersContinuously = false

        let coordinator = context.coordinator
        coordinator.profile = profile
        coordinator.displayStyle = displayStyle
        coordinator.lightingStyle = lightingStyle
        coordinator.pose = pose
        coordinator.loadRealisticMesh(for: view)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        let coordinator = context.coordinator
        coordinator.pose = pose
        coordinator.profile = profile
        coordinator.displayStyle = displayStyle
        coordinator.lightingStyle = lightingStyle
        let needsRebuild = coordinator.lastBuiltProfile != profile
            || coordinator.lastBuiltDisplayStyle != displayStyle
            || coordinator.lastBuiltLightingStyle != lightingStyle
            || view.scene == nil

        if needsRebuild {
            let oldPosition = view.pointOfView?.position
            let oldOrientation = view.pointOfView?.orientation
            let scene = FigureSceneBuilder.makeScene(profile: profile, pose: pose,
                                                     displayStyle: displayStyle, lightingStyle: lightingStyle)
            view.scene = scene
            if let modelRoot = coordinator.modelRoot {
                FigureSceneBuilder.attachRealisticBaseMesh(modelRoot, to: scene,
                                                           profile: profile, displayStyle: displayStyle)
                coordinator.rig?.apply(pose)
            }
            let camera = scene.rootNode.childNode(withName: "figureCamera", recursively: false)
            if let camera {
                if let oldPosition, coordinator.modelRoot == nil { camera.position = oldPosition }
                if let oldOrientation, coordinator.modelRoot == nil { camera.orientation = oldOrientation }
                view.pointOfView = camera
            }
            coordinator.lastBuiltProfile = profile
            coordinator.lastBuiltDisplayStyle = displayStyle
            coordinator.lastBuiltLightingStyle = lightingStyle
        } else if let scene = view.scene {
            FigureSceneBuilder.apply(pose: pose, to: scene, profile: profile)
            coordinator.rig?.apply(pose)
        }

        if coordinator.modelRoot == nil {
            coordinator.loadRealisticMesh(for: view)
        }
    }

    final class Coordinator {
        var profile: BodyProfile?
        var displayStyle: FigureDisplayStyle?
        var lightingStyle: FigureLightingStyle?
        var lastBuiltProfile: BodyProfile?
        var lastBuiltDisplayStyle: FigureDisplayStyle?
        var lastBuiltLightingStyle: FigureLightingStyle?
        var pose = FigurePose()
        var modelRoot: SCNNode?
        var rig: FemaleFigureRig?
        private var isLoadingModel = false
        private var attemptedModelLoad = false

        func loadRealisticMesh(for view: SCNView) {
            guard !isLoadingModel && !attemptedModelLoad && modelRoot == nil else { return }
            isLoadingModel = true
            attemptedModelLoad = true
            FemaleBaseMeshLoader.load { [weak self, weak view] loadedScene in
                guard let self else { return }
                self.isLoadingModel = false
                guard let loadedScene, let view, let activeScene = view.scene else {
                    NSLog("Using procedural Figure Studio fallback; realistic base mesh is unavailable.")
                    return
                }

                let root = SCNNode()
                root.name = "realisticFemaleMeshRoot"
                for child in Array(loadedScene.rootNode.childNodes) {
                    child.removeFromParentNode()
                    root.addChildNode(child)
                }
                self.modelRoot = root
                self.rig = FemaleFigureRig(root: root)
                FigureSceneBuilder.attachRealisticBaseMesh(
                    root, to: activeScene,
                    profile: self.profile ?? .defaultProfile,
                    displayStyle: self.displayStyle ?? .realistic
                )
                self.rig?.apply(self.pose)
                self.lastBuiltProfile = self.profile
                self.lastBuiltDisplayStyle = self.displayStyle
                self.lastBuiltLightingStyle = self.lightingStyle
            }
        }
    }
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) { }
}
