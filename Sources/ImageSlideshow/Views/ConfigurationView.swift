import SwiftUI

/// View that provides configuration settings for the slideshow
struct ConfigurationView: View {
    @ObservedObject var viewModel: SlideshowViewModel
    
    // Local state for editing configuration
    @State private var transitionDuration: Double
    @State private var transitionEffect: TransitionEffect
    
    init(viewModel: SlideshowViewModel) {
        self.viewModel = viewModel
        // Initialize state from current configuration
        _transitionDuration = State(initialValue: viewModel.configuration.transitionDuration)
        _transitionEffect = State(initialValue: viewModel.configuration.transitionEffect)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.headline)
            
            // Transition Duration Slider
            VStack(alignment: .leading, spacing: 8) {
                Text("Transition Duration: \(String(format: "%.0f", transitionDuration)) seconds")
                    .font(.subheadline)
                
                Slider(
                    value: $transitionDuration,
                    in: 1...60,
                    step: 1
                ) {
                    Text("Duration")
                } minimumValueLabel: {
                    Text("1s")
                        .font(.caption)
                } maximumValueLabel: {
                    Text("60s")
                        .font(.caption)
                }
                .onChange(of: transitionDuration) { _ in
                    applyConfiguration()
                }
            }
            
            // Transition Effect Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Transition Effect")
                    .font(.subheadline)
                
                Picker("Effect", selection: $transitionEffect) {
                    Text("Slide").tag(TransitionEffect.slide)
                    Text("None").tag(TransitionEffect.none)
                }
                .pickerStyle(.segmented)
                .onChange(of: transitionEffect) { _ in
                    applyConfiguration()
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 250)
    }
    
    /// Applies the current configuration settings to the view model
    private func applyConfiguration() {
        let newConfig = SlideshowConfiguration(
            transitionDuration: transitionDuration,
            transitionEffect: transitionEffect,
            lastSelectedFolderPath: viewModel.configuration.lastSelectedFolderPath
        )
        viewModel.updateConfiguration(newConfig)
    }
}
