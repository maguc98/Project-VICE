import SwiftUI
import SceneKit

struct ContentView: View {
    @Binding var profile: BodyProfile
    @State private var selectedSection: MeasurementSection = .body
    @State private var pose = FigurePose()
    @AppStorage("figureStudio.savedPose") private var savedPoseData: Data = Data()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                FigureViewport(profile: profile, pose: pose)
                    .frame(maxWidth: .infinity)
                    .frame(height: 390)
                    .background(Color(red: 0.94, green: 0.96, blue: 0.97))

                Picker("身体部位", selection: $selectedSection) {
                    ForEach(MeasurementSection.allCases) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 16)

                if selectedSection == .pose {
                    PoseControlPanel(
                        pose: $pose,
                        hasSavedPose: !savedPoseData.isEmpty,
                        onSave: {
                            if let data = try? JSONEncoder().encode(pose) {
                                savedPoseData = data
                            }
                        },
                        onLoad: {
                            if let saved = try? JSONDecoder().decode(FigurePose.self, from: savedPoseData) {
                                pose = saved
                            }
                        }
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("重置") { profile = .defaultProfile; pose = FigurePose() }
                }
            }
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
    let hasSavedPose: Bool
    let onSave: () -> Void
    let onLoad: () -> Void

    var body: some View {
        Form {
            Section("手臂姿势") {
                AngleControl(title: "双侧肩部抬起", value: $pose.armRaiseDegrees, range: -35...150)
                AngleControl(title: "双侧肘部弯曲", value: $pose.elbowBendDegrees, range: 0...145)
            }
            Section("左腿") {
                AngleControl(title: "髋部前后摆动", value: $pose.leftHipFlexionDegrees, range: -90...90)
                AngleControl(title: "髋部外展", value: $pose.leftHipAbductionDegrees, range: -45...45)
                AngleControl(title: "膝部弯曲", value: $pose.leftKneeBendDegrees, range: 0...135)
                AngleControl(title: "脚踝活动", value: $pose.leftAnkleFlexionDegrees, range: -45...45)
            }
            Section("右腿") {
                AngleControl(title: "髋部前后摆动", value: $pose.rightHipFlexionDegrees, range: -90...90)
                AngleControl(title: "髋部外展", value: $pose.rightHipAbductionDegrees, range: -45...45)
                AngleControl(title: "膝部弯曲", value: $pose.rightKneeBendDegrees, range: 0...135)
                AngleControl(title: "脚踝活动", value: $pose.rightAnkleFlexionDegrees, range: -45...45)
            }
            Section("姿势管理") {
                Button("保存当前姿势", action: onSave)
                Button("读取已保存姿势", action: onLoad)
                    .disabled(!hasSavedPose)
                Button("恢复自然站姿", role: .destructive) { pose = FigurePose() }
            }
        }
        .scrollContentBackground(.hidden)
    }
}

private struct AngleControl: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value, specifier: "%.0f")°")
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

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = FigureSceneBuilder.makeScene(profile: profile, pose: pose)
        view.backgroundColor = UIColor(red: 0.94, green: 0.96, blue: 0.97, alpha: 1)
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.antialiasingMode = .multisampling4X
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        // Preserve the user's orbit-camera position while the body proportions update.
        let oldCameraPosition = view.pointOfView?.position
        let oldCameraOrientation = view.pointOfView?.orientation
        let scene = FigureSceneBuilder.makeScene(profile: profile, pose: pose)
        view.scene = scene
        if let camera = scene.rootNode.childNodes.first(where: { $0.camera != nil }) {
            if let oldCameraPosition { camera.position = oldCameraPosition }
            if let oldCameraOrientation { camera.orientation = oldCameraOrientation }
            view.pointOfView = camera
        }
    }
}
