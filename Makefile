NORM_FILE := ""

BASE_CMD := statsimi --norm_file=$(NORM_FILE)
CUTOFFDIST := 1000

# probability a station is spiced
SPICE := --spice=0.5

EVAL_ARGS := --unique --clean_data

EVAL_RES_DIR := data/evaluation_run
GEODATA_DIR := data/geodata

.SECONDARY:

.PHONY: clean-geodata install eval

install: osmfilter osmconvert
	@echo Installing statsimi
	@git clone --recurse-submodules https://github.com/ad-freiburg/statsimi
	@cd statsimi && pip3 install wheel && pip3 install .

eval: freiburg_eval london_eval dach_eval 

osmfilter:
	@echo Installing osmfilter
	@curl -sS --insecure -L http://m.m.i24.cc/osmfilter.c | cc -x c - -O3 -o $@

osmconvert:
	@echo Installing osmconvert
	@curl -sS --insecure -L http://m.m.i24.cc/osmconvert.c | cc -x c - -lz -O3 -o $@

$(EVAL_RES_DIR)/%/:
	mkdir -p $@

%_eval: $(EVAL_RES_DIR)/%/geodist/output.txt $(EVAL_RES_DIR)/%/editdist/output.txt $(EVAL_RES_DIR)/%/jaccard/output.txt $(EVAL_RES_DIR)/%/ped/output.txt $(EVAL_RES_DIR)/%/bts/output.txt $(EVAL_RES_DIR)/%/jaro/output.txt $(EVAL_RES_DIR)/%/jaro_winkler/output.txt $(EVAL_RES_DIR)/%/tfidf/output.txt $(EVAL_RES_DIR)/%/rf_topk/output.txt $(EVAL_RES_DIR)/%/geodist-editdist/output.txt $(EVAL_RES_DIR)/%/geodist-tfidf/output.txt $(EVAL_RES_DIR)/%/geodist-bts/output.txt
	@echo Finished evaluation run for $*

$(EVAL_RES_DIR)/%/geodist/output.txt: $(GEODATA_DIR)/%-stations.osm | $(EVAL_RES_DIR)/%/geodist/
	@echo == Evaluating geodist thresholds for $* ==
	$(BASE_CMD) evaluate-par --test $< --method="geodist" --modeltestargs="geodist_threshold=0.1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 250, 300, 350, 400, 450, 500" --cutoffdist=$(CUTOFFDIST) --topk 0 $(SPICE) --eval-out $| --model_out "" $(EVAL_ARGS)  2>&1 | tee $@.tmp
	@mv $@.tmp $@


$(EVAL_RES_DIR)/%/editdist/output.txt: $(GEODATA_DIR)/%-stations.osm | $(EVAL_RES_DIR)/%/editdist/
	@echo == Evaluating editdist thresholds for $* ==
	$(BASE_CMD) evaluate-par --test $< --method="editdist" --modeltestargs="editdist_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --cutoffdist=$(CUTOFFDIST) --topk 0 $(SPICE) --eval-out $|  --model_out "" $(EVAL_ARGS) 2>&1 | tee $@.tmp
	@mv $@.tmp $@


$(EVAL_RES_DIR)/%/jaccard/output.txt: $(GEODATA_DIR)/%-stations.osm | $(EVAL_RES_DIR)/%/jaccard/
	@echo == Evaluating jaccard thresholds for $* ==
	$(BASE_CMD) evaluate-par --test $< --method="jaccard" --modeltestargs="jaccard_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --cutoffdist=$(CUTOFFDIST) --topk 0 $(SPICE) --eval-out $|  --model_out "" $(EVAL_ARGS) 2>&1 | tee $@.tmp
	@mv $@.tmp $@


$(EVAL_RES_DIR)/%/tfidf/output.txt: $(GEODATA_DIR)/%-stations.osm | $(EVAL_RES_DIR)/%/tfidf/
	@echo == Evaluating tfidf thresholds for $* ==
	$(BASE_CMD) evaluate-par -p 0.2 --train $< --method="tfidf" --modeltestargs="tfidf_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --cutoffdist=$(CUTOFFDIST) --topk 0 $(SPICE) --eval-out $|  --model_out "" $(EVAL_ARGS) 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/jaro/output.txt: $(GEODATA_DIR)/%-stations.osm | $(EVAL_RES_DIR)/%/jaro/
	@echo == Evaluating Jaro similarity thresholds for $* ==
	$(BASE_CMD) evaluate-par --test $< --method="jaro" --modeltestargs="jaro_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --cutoffdist=$(CUTOFFDIST) --topk 0 $(SPICE) --eval-out $| --model_out "" $(EVAL_ARGS) 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/jaro_winkler/output.txt: $(GEODATA_DIR)/%-stations.osm | $(EVAL_RES_DIR)/%/jaro_winkler/
	@echo == Evaluating Jaro-Winkler similarity thresholds for $* ==
	$(BASE_CMD) evaluate-par --test $< --method="jaro_winkler" --modeltestargs="jaro_winkler_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --cutoffdist=$(CUTOFFDIST) --topk 0 $(SPICE) --eval-out $| --model_out "" $(EVAL_ARGS) 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/bts/output.txt: $(GEODATA_DIR)/%-stations.osm | $(EVAL_RES_DIR)/%/bts/
	@echo == Evaluating BTS thresholds for $* ==
	$(BASE_CMD) evaluate-par --test $< --method="bts" --modeltestargs="bts_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --cutoffdist=$(CUTOFFDIST) --topk 0 $(SPICE) --eval-out $| --model_out "" $(EVAL_ARGS) 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/ped/output.txt: $(GEODATA_DIR)/%-stations.osm | $(EVAL_RES_DIR)/%/ped/
	@echo == Evaluating ped thresholds for $* ==
	$(BASE_CMD) evaluate-par --test $< --method="ped" --modeltestargs="ped_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --cutoffdist=$(CUTOFFDIST) --topk 0 $(SPICE) --eval-out $| --model_out "" $(EVAL_ARGS) 2>&1 | tee $@.tmp
	mv $@.tmp $@

$(EVAL_RES_DIR)/%/sed/output.txt: $(GEODATA_DIR)/%-stations.osm | $(EVAL_RES_DIR)/%/sed/
	@echo == Evaluating sed thresholds for $* ==
	$(BASE_CMD) evaluate-par --test $< --method="sed" --modeltestargs="sed_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --cutoffdist=$(CUTOFFDIST) --topk 0 $(SPICE) --eval-out $| --model_out "" $(EVAL_ARGS) 2>&1 | tee $@.tmp
	mv $@.tmp $@

$(EVAL_RES_DIR)/%/geodist-editdist/output.txt: $(GEODATA_DIR)/%-stations.osm | $(EVAL_RES_DIR)/%/geodist-editdist/
	@echo == Evaluating combination of geodist and editdist using soft voting approach for $* ==
	$(BASE_CMD) evaluate-par --test $< --method="geodist, editdist" --modeltestargs="geodist_threshold=0.1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 250, 300, 350, 400, 450, 500;editdist_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --voting='soft' --cutoffdist=$(CUTOFFDIST) --topk 0 $(SPICE) --eval-out $| --model_out "" $(EVAL_ARGS) 2>&1 | tee $@.tmp
	mv $@.tmp $@

$(EVAL_RES_DIR)/%/geodist-bts/output.txt: $(GEODATA_DIR)/%-stations.osm | $(EVAL_RES_DIR)/%/geodist-bts/
	@echo == Evaluating combination of geodist and BTS using soft voting approach for $* ==
	$(BASE_CMD) evaluate-par --test $< --method="geodist, bts" --modeltestargs="geodist_threshold=0.1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 250, 300, 350, 400, 450, 500;bts_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --voting='soft' --cutoffdist=$(CUTOFFDIST) --topk 0 $(SPICE) --eval-out $| --model_out "" $(EVAL_ARGS) 2>&1 | tee $@.tmp
	mv $@.tmp $@

$(EVAL_RES_DIR)/%/geodist-tfidf/output.txt: $(GEODATA_DIR)/%-stations.osm | $(EVAL_RES_DIR)/%/geodist-tfidf/
	@echo == Evaluating combination of geodist and tfidf using soft voting approach for $* ==
	$(BASE_CMD) evaluate-par --train $< --method="geodist, tfidf" --modeltestargs="geodist_threshold=0.1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 250, 300, 350, 400, 450, 500;tfidf_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --voting='soft' --cutoffdist=$(CUTOFFDIST) --topk 0 $(SPICE) --eval-out $| --model_out "" $(EVAL_ARGS) 2>&1 | tee $@.tmp
	mv $@.tmp $@

$(EVAL_RES_DIR)/%/rf_topk/output.txt: $(GEODATA_DIR)/%-stations.osm | $(EVAL_RES_DIR)/%/rf_topk/
	@echo == Evaluating topk qgram number for $* ==
	$(BASE_CMD) evaluate-par --train $< --method="rf" --fbtestargs="topk=0, 5, 10, 25, 50, 100, 250, 500, 1000, 1500, 2000, 2500" --cutoffdist=$(CUTOFFDIST) $(SPICE) --eval-out $| --model_out "" $(EVAL_ARGS) 2>&1 | tee $@.tmp
	mv $@.tmp $@

$(EVAL_RES_DIR)/%/rf_pos_pairs/output.txt: $(GEODATA_DIR)/%-stations.osm | $(EVAL_RES_DIR)/%/rf_pos_pairs/
	@echo == Evaluating number of pos pairs $* ==
	$(BASE_CMD) evaluate-par --train $< --method="rf" --fbtestargs="num_pos_pairs=0, 1, 2, 3, 4, 5" --cutoffdist=$(CUTOFFDIST) $(SPICE) --eval-out $| --model_out "" $(EVAL_ARGS) 2>&1 | tee $@.tmp
	mv $@.tmp $@

$(GEODATA_DIR)/%-stations.osm: $(GEODATA_DIR)/%-latest.o5m osmfilter
	@echo "Filtering osm stations..."
	@./osmfilter $< --keep="public_transport=stop public_transport=stop_position public_transport=platform public_transport=station public_transport=halt highway=bus_stop railway=stop railway=station railway=halt railway=tram_stop railway=platform tram=stop subway=stop" --keep-relations="public_transport=stop_area public_transport=stop_area_group" --drop-version -o=$@

$(GEODATA_DIR)/dach-latest.o5m:
	@mkdir -p $(GEODATA_DIR)
	@echo "Downloading DACH osm stations..."
	@curl --insecure -L "http://download.geofabrik.de/europe/dach-latest.osm.pbf" | ./osmconvert - --drop-author --drop-version -o=$@

$(GEODATA_DIR)/uk-latest.o5m:
	@mkdir -p $(GEODATA_DIR)
	@echo "Downloading UK osm stations..."
	@curl --insecure -L "https://download.geofabrik.de/europe/great-britain-latest.osm.pbf" | ./osmconvert - --drop-author --drop-version -o=$@

$(GEODATA_DIR)/london-latest.o5m:
	@mkdir -p $(GEODATA_DIR)
	@echo "Downloading London osm stations..."
	@curl --insecure -L "http://download.geofabrik.de/europe/great-britain/england/greater-london-latest.osm.pbf" | ./osmconvert - --drop-author --drop-version -o=$@

$(GEODATA_DIR)/freiburg-regbz-latest.o5m:
	@mkdir -p $(GEODATA_DIR)
	@echo "Downloading Freiburg RegBZ osm stations..."
	@curl --insecure -L "http://download.geofabrik.de/europe/germany/baden-wuerttemberg/freiburg-regbez-latest.osm.pbf" | ./osmconvert - --drop-author --drop-version -o=$@

$(GEODATA_DIR)/freiburg-latest.o5m: $(GEODATA_DIR)/freiburg-regbz-latest.o5m osmconvert
	@mkdir -p $(GEODATA_DIR)
	@./osmconvert $< -b=7.713899,47.9285939,7.973421,48.075549 > $@

clean:
	@rm -rf $(GEODATA_DIR)
	@rm -rf $(EVAL_RES_DIR)
	@find . -name "*.pyc" | xargs rm -f
	@find . -name "__pycache__" | xargs rm -rf
