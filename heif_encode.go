package goheif

import (
	"image"
	"image/draw"
	"io"
	"io/ioutil"
	"os"
)

// EncodeOptions is heif encode options
type EncodeOptions struct {
	Quality      int
	Compression  Compression
	LosslessMode LosslessMode
	LoggingLevel LoggingLevel
}

// EncodeOption ...
type EncodeOption func(opts *EncodeOptions)

// WithEncodeQuality ...
func WithEncodeQuality(Quality int) EncodeOption {
	return func(opts *EncodeOptions) {
		opts.Quality = Quality
	}
}

// WithEncodeCompression ...
func WithEncodeCompression(Compression Compression) EncodeOption {
	return func(opts *EncodeOptions) {
		opts.Compression = Compression
	}
}

// WithEncodeLosslessMode ...
func WithEncodeLosslessMode(LosslessMode LosslessMode) EncodeOption {
	return func(opts *EncodeOptions) {
		opts.LosslessMode = LosslessMode
	}
}

// WithEncodeLoggingLevel ...
func WithEncodeLoggingLevel(LoggingLevel LoggingLevel) EncodeOption {
	return func(opts *EncodeOptions) {
		opts.LoggingLevel = LoggingLevel
	}
}

// Encode to heif
func Encode(w io.Writer, img image.Image, opt ...EncodeOption) error {
	opts := EncodeOptions{
		Quality:      100,
		Compression:  CompressionHEVC,
		LosslessMode: LosslessModeEnabled,
		LoggingLevel: LoggingLevelBasic,
	}
	for _, o := range opt {
		o(&opts)
	}

	switch im := img.(type) {
	case *image.RGBA, *image.RGBA64, *image.Gray /*, *image.YCbCr*/ : //底层只支持了这几种
	default: // 其他的转为 RGBA
		img = toRGBA(im)
	}

	ctx, err := EncodeFromImage(img, opts.Compression, opts.Quality, opts.LosslessMode, opts.LoggingLevel)
	if err != nil {
		return err
	}

	// TODO 研究除了写文件还有没有其他办法, 或者考虑用 mmap 内存映射的方式?
	tempFile, err := ioutil.TempFile("", "*.heif")
	if err != nil {
		return err
	}
	tmpFilename := tempFile.Name()
	defer os.Remove(tmpFilename)

	if err := ctx.WriteToFile(tmpFilename); err != nil {
		return err
	}

	if _, err := io.Copy(w, tempFile); err != nil {
		return err
	}
	return nil
}

func toRGBA(im image.Image) *image.RGBA {
	b := im.Bounds()
	m := image.NewRGBA(image.Rect(0, 0, b.Dx(), b.Dy()))

	draw.Draw(m, m.Bounds(), im, b.Min, draw.Src)
	return m
}
