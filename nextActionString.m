
function a = nextActionString(s)
    switch s
        case NIPState.Ready
            a = 'Open Image File';
            
        case NIPState.ReadImages
            a = 'Segment Nucleus Image';
            
        case NIPState.SegmentedNucleusImageOnce
            a = 'Segment Nucleus Image Background';
        case NIPState.SegmentedNucleusImageTwice
            a = 'Separate Nuclei Via Morphological Opening';
        case NIPState.OpenedNucleusMask
            a = 'Identify Nucleus Clusters';
        case NIPState.IdentifiedNucleusClusters
            a = 'Calculate Typical Nucleus Area';
        case NIPState.CalculatedNominalMeanNucleusArea
            a = 'Calculate Minimum Nucleus Area';
        case NIPState.CalculatedMinNucleusArea
            a = 'Segment Cell Image';
            
        case NIPState.SegmentedCells
            a = 'Isolate Cell Bodies';
        case NIPState.SeparatedBodiesFromNeurites
            a = 'Segment Neurites in Background';
        case NIPState.ResegmentedNeurites
            a = 'Close Neurite Mask';
        case NIPState.ClosedNeuriteMask
            a = 'Create Graph';
        
        case NIPState.CreatedGraph
            a = 'Find Neurite Paths';
        case NIPState.ComputedPaths
            a = 'Save Parameters';
        case NIPState.Done
            a = 'Quit';
        otherwise
            error('[nextActionString] Unexpected state: %s', char(s));
    end
end

