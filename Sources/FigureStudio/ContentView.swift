import SwiftUI
import SceneKit

struct ContentView: View {
    @Binding var profile: BodyProfile
    @State private var selectedSection: MeasurementSection = .body
    @State private var pose = FigurePose()

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
                    PoseControlPanel(pose: $pose)
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

    var body: some View {
        Form {
            Section("手臂姿势") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("肩部抬起")
                        Spacer()
                        Text("\(pose.armRaiseDegrees, specifier: "%.0f")°")
                            .monospacedDigit().foregroundStyle(.secondary)
                    }
                    Slider(value: $pose.armRaiseDegrees, in: -35...150, step: 1)
                    HStack {
                        Text("肘部弯曲")
                        Spacer()
                        Text("\(pose.elbowBendDegrees, specifier: "%.0f")°")
                            .monospacedDigit().foregroundStyle(.secondary)
                    }
                    Slider(value: $pose.elbowBendDegrees, in: 0...145, step: 1)
                }
            }
            Section {
                Button("恢复自然站姿") { pose = FigurePose() }
            }
        }
        .scrollContentBackground(.hidden)
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
        let scene = FigureSceneBuilder.makeScene(profile: profile)
        view.scene = scene
        if let camera = scene.rootNode.childNodes.first(where: { $0.camera != nil }) {
            if let oldCameraPosition { camera.position = oldCameraPosition }
            if let oldCameraOrientation { camera.orientation = oldCameraOrientation }
            view.pointOfView = camera
        }
    }
}
