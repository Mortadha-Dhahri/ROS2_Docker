#!/bin/bash
# =========================
# db3 to MCAP Converter (ROS2 Humble)
# =========================
# Usage:
#   ./convert_to_mcap.sh /bags/<session_folder>
#   ./convert_to_mcap.sh /bags/<session_folder> --delete-source
# =========================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

INPUT_BAG="${1}"
DELETE_SOURCE=false

for arg in "$@"; do
    if [ "${arg}" == "--delete-source" ]; then
        DELETE_SOURCE=true
    fi
done

if [ -z "${INPUT_BAG}" ]; then
    echo -e "${CYAN}Usage:${NC}"
    echo -e "  ./convert_to_mcap.sh /bags/<session_folder> [--delete-source]"
    exit 1
fi

if [ ! -d "${INPUT_BAG}" ]; then
    echo -e "${RED}[error]${NC} Input bag folder not found: ${INPUT_BAG}"
    exit 1
fi

DB3_COUNT=$(find "${INPUT_BAG}" -name "*.db3" | wc -l)
if [ "${DB3_COUNT}" -eq 0 ]; then
    echo -e "${RED}[error]${NC} No .db3 files found in: ${INPUT_BAG}"
    exit 1
fi

if [ -f /opt/ros/humble/setup.bash ]; then
    source /opt/ros/humble/setup.bash
else
    echo -e "${RED}[error]${NC} ROS2 Humble not found at /opt/ros/humble/setup.bash"
    exit 1
fi

OUTPUT_BAG="${INPUT_BAG%/}_mcap"

echo -e "${CYAN}[convert]${NC} Input  : ${INPUT_BAG}"
echo -e "${CYAN}[convert]${NC} Output : ${OUTPUT_BAG}"
echo -e "${CYAN}[convert]${NC} db3 files found: ${DB3_COUNT}"
echo ""

if [ -d "${OUTPUT_BAG}" ]; then
    echo -e "${YELLOW}[warn]${NC} Output folder already exists: ${OUTPUT_BAG}"
    echo -e "       Delete it first or rename the output manually."
    exit 1
fi

# -------------------------
# Write YAML options file
# Must specify both input storage_id and output storage_id
# -------------------------
YAML_FILE=$(mktemp /tmp/convert_options_XXXXXX.yaml)

cat > "${YAML_FILE}" << YAML
output_bags:
  - uri: ${OUTPUT_BAG}
    storage_id: mcap
    all: true
YAML

echo -e "${CYAN}[convert]${NC} Starting conversion..."

ros2 bag convert \
    --input "${INPUT_BAG}" sqlite3 \
    --output-options "${YAML_FILE}"

rm -f "${YAML_FILE}"

MCAP_COUNT=$(find "${OUTPUT_BAG}" -name "*.mcap" | wc -l)

if [ "${MCAP_COUNT}" -eq 0 ]; then
    echo -e "${RED}[error]${NC} Conversion finished but no .mcap files were produced."
    exit 1
fi

echo ""
echo -e "${GREEN}[done]${NC} Conversion successful."
echo -e "${GREEN}[done]${NC} MCAP files written to: ${OUTPUT_BAG}"
echo -e "${GREEN}[done]${NC} .mcap files produced : ${MCAP_COUNT}"

if [ "${DELETE_SOURCE}" = true ]; then
    echo ""
    echo -e "${YELLOW}[warn]${NC} --delete-source flag set. Removing original db3 bag: ${INPUT_BAG}"
    rm -rf "${INPUT_BAG}"
    echo -e "${GREEN}[done]${NC} Original db3 bag deleted."
fi

echo ""
echo -e "${CYAN}[info]${NC} Inspect your new bag with:"
echo -e "       ros2 bag info ${OUTPUT_BAG}"
echo -e "       ros2 bag play ${OUTPUT_BAG} --storage mcap"