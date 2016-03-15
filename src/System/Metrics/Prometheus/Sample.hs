module System.Metrics.Prometheus.Sample where


import           Data.Map                           (Map)

import qualified System.Metrics.Prometheus.Counter  as Counter
import qualified System.Metrics.Prometheus.Gauge    as Gauge
import           System.Metrics.Prometheus.Metric   (Metric)
import qualified System.Metrics.Prometheus.Metric   as Metric
import           System.Metrics.Prometheus.MetricId (MetricId)
import           System.Metrics.Prometheus.Registry (Registry, unRegistry)


newtype CounterSample = CounterSample { unCounterSample :: Int }

newtype GaugeSample = GaugeSample { unGaugeSample :: Double }


data HistogramSample =
    HistogramSample
    { histBuckets :: Map Double Int
    , histSum     :: Int
    , histCount   :: Int
    }


data SummarySample =
    SummarySample
    { sumQuantiles :: Map Double Int
    , sumSum       :: Int
    , sumCount     :: Int
    }


data MetricSample
    = Counter CounterSample
    | Gauge GaugeSample
    | Histogram HistogramSample
    | Summary SummarySample


metricSample :: (CounterSample -> a) -> (GaugeSample -> a)
             -> (HistogramSample -> a) -> (SummarySample -> a)
             -> MetricSample -> a
metricSample f _ _ _ (Counter s)   = f s
metricSample _ f _ _ (Gauge s)     = f s
metricSample _ _ f _ (Histogram s) = f s
metricSample _ _ _ f (Summary s)   = f s


newtype RegistrySample = RegistrySample { unRegistrySample :: Map MetricId MetricSample }


sample :: Registry -> IO RegistrySample
sample = fmap RegistrySample . mapM sampleMetric . unRegistry


sampleMetric :: Metric -> IO MetricSample
sampleMetric (Metric.Counter count) = Counter . CounterSample <$> Counter.view count
sampleMetric (Metric.Gauge gauge) = Gauge . GaugeSample <$> Gauge.get gauge