library("ggplot2")
library("ggpubr")
library("tikzDevice")

extract.legend<-function(plot){
	tmp <- ggplot_gtable(ggplot_build(plot))
	leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
	legend <- tmp$grobs[[leg]]
	return (legend)
}

samples <- data.frame(n=1:100)

samples$lin <- samples$n * 4
samples$nlog <- samples$n * log2(samples$n)

samples$lin.ymin.small <- samples$lin * 0.95
samples$lin.ymin.large <- samples$lin * 0.8

samples$lin.ymax.small <- samples$lin * 1.05
samples$lin.ymax.large <- samples$lin * 1.2


samples$nlog.ymin.small <- samples$nlog * 0.95
samples$nlog.ymin.large <- samples$nlog * 0.8

samples$nlog.ymax.small <- samples$nlog * 1.05
samples$nlog.ymax.large <- samples$nlog * 1.2

plot.small <- ggplot(samples, aes(n)) +
	geom_ribbon(aes(ymin=lin.ymin.small, ymax=lin.ymax.small, fill="4n"), alpha=0.5, show.legend=F) +
	geom_ribbon(aes(ymin=nlog.ymin.small, ymax=nlog.ymax.small, fill="n*log(n)"), alpha=0.5, show.legend=F) +
	geom_line(aes(x=n, y=lin, colour="4n")) +
	geom_line(aes(x=n, y=nlog, colour="nlog(n)")) +
	ggtitle("5\\% error") +
	ylim(0, 800) +
	ylab("Execution time [ms]") +
	theme(legend.title=element_blank())

plot.large <- ggplot(samples, aes(n)) +
	geom_ribbon(aes(ymin=lin.ymin.large, ymax=lin.ymax.large, alpha=0.5, fill="4n"), show.legend=F) +
	geom_ribbon(aes(ymin=nlog.ymin.large, ymax=nlog.ymax.large, alpha=0.5, fill="n*log(n)"), show.legend=F) +
	geom_line(aes(x=n, y=lin, colour="4n")) +
	geom_line(aes(x=n, y=nlog, colour="nlog(n)")) +
	ggtitle("20\\% error") +
	ylim(0, 800) +
	theme(legend.title=element_blank(), axis.title.y=element_blank())

tikz(file="stability-illustration.tex", width=5.5, height=4)

ggarrange(
	  plot.small + theme(legend.position="none"), 
	  plot.large + theme(legend.position="none"), 
	  common.legend=T,
	  ncol=2)

dev.off()
