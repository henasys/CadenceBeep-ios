import SwiftUI

struct ContentView: View {
    @StateObject private var engine = BeepEngine()

    let presets = [150, 160, 170, 180]
    let accentOptions = [0, 2, 3, 4]

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                // Title
                HStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.title2)
                    Text("Cadence Beep")
                        .font(.title2.bold())
                }
                .foregroundStyle(.primary)
                .padding(.top, 20)

                // SPM Display
                VStack(spacing: 8) {
                    Text("\(engine.spm)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Text("SPM")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 24) {
                        StepButton(systemName: "minus", size: .large) {
                            adjustSPM(-1)
                        }
                        StepButton(systemName: "plus", size: .large) {
                            adjustSPM(1)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal)

                // Presets
                HStack(spacing: 12) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            withAnimation(.snappy) { engine.spm = preset }
                            engine.updateTiming()
                        } label: {
                            Text("\(preset)")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(engine.spm == preset ? Color.accentColor : Color(.tertiarySystemBackground))
                                )
                                .foregroundStyle(engine.spm == preset ? .white : .primary)
                        }
                    }
                }
                .padding(.horizontal)

                // Accent
                VStack(alignment: .leading, spacing: 8) {
                    Text("강박")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(accentOptions, id: \.self) { opt in
                            Button {
                                engine.accentEvery = opt
                            } label: {
                                Text(opt == 0 ? "끄기" : "\(opt)박")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(engine.accentEvery == opt ? Color.accentColor : Color(.tertiarySystemBackground))
                                    )
                                    .foregroundStyle(engine.accentEvery == opt ? .white : .primary)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Sound selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("사운드")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(BeepSound.allCases) { sound in
                            Button {
                                engine.beepSound = sound
                            } label: {
                                SoundOptionLabel(sound: sound, selected: engine.beepSound == sound)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Volume
                HStack(spacing: 12) {
                    Image(systemName: "speaker.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Slider(value: $engine.volume, in: 0...1)
                        .tint(.accentColor)
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal)

                Spacer()

                // Start/Stop Button
                Button {
                    if engine.isPlaying {
                        engine.stop()
                    } else {
                        engine.start()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: engine.isPlaying ? "stop.fill" : "play.fill")
                        Text(engine.isPlaying ? "STOP" : "START")
                            .font(.title3.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(engine.isPlaying ? Color.red : Color.accentColor)
                    )
                    .foregroundStyle(.white)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }

    private func adjustSPM(_ delta: Int) {
        let newValue = max(100, min(220, engine.spm + delta))
        withAnimation(.snappy) { engine.spm = newValue }
        engine.updateTiming()
    }
}

struct SoundOptionLabel: View {
    let sound: BeepSound
    let selected: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.caption)
            Text(sound.rawValue)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(selected ? Color.accentColor.opacity(0.15) : Color(.tertiarySystemBackground))
        )
        .foregroundStyle(selected ? Color.accentColor : Color.primary)
    }
}

struct StepButton: View {
    let systemName: String
    enum Size { case large, small }
    let size: Size
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(size == .large ? .title2.bold() : .body.bold())
                .frame(width: size == .large ? 56 : 40, height: size == .large ? 56 : 40)
                .background(
                    Circle()
                        .fill(Color(.tertiarySystemBackground))
                )
        }
        .repeatBehaviorIfAvailable()
    }
}

private extension View {
    @ViewBuilder
    func repeatBehaviorIfAvailable() -> some View {
        if #available(iOS 17.0, *) {
            self.buttonRepeatBehavior(.enabled)
        } else {
            self
        }
    }
}

#Preview {
    ContentView()
}
